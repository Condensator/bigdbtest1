SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[PopulateTaxDepAmortJobExtract]
(
               @EntityType NVARCHAR(30),
               @CreatedById BIGINT,
               @CreatedTime DATETIMEOFFSET,
               @FilterOption NVARCHAR(10),
               @AllFilterOption NVARCHAR(10),
               @OneFilterOption NVARCHAR(10),
               @RangeFilterOption NVARCHAR(10),
               @FromAssetId BIGINT NULL,
               @ToAssetId BIGINT NULL,
               @ContractId BIGINT NULL,
               @JobStepInstanceId BIGINT, 
               @ValidLegalEntityIds IdList READONLY,
			   @ReversalPostDate DATE
)
AS
BEGIN
               SET NOCOUNT ON
               DECLARE @True BIT = 1
               DECLARE @False BIT = 0
               DECLARE @Lease NVARCHAR(10) = 'Lease'
               DECLARE @Loan NVARCHAR(10) = 'Loan'
               DECLARE @Asset NVARCHAR(10) = 'Asset'
               DECLARE @BlendedItem NVARCHAR(15) = 'BlendedItem'
               DECLARE @Terminated NVARCHAR(15) = 'Terminated'
               DECLARE @Inventory NVARCHAR(15) = 'Inventory'
               DECLARE @Leased NVARCHAR(15) = 'Leased'
               DECLARE @Sold NVARCHAR(15) = 'Sold'
               DECLARE @Scrap NVARCHAR(15) = 'Scrap'
               DECLARE @InvestorLeased NVARCHAR(20) = 'InvestorLeased'
               DECLARE @Commenced NVARCHAR(15) = 'Commenced'
               DECLARE @December NVARCHAR(15) = 'December'
               DECLARE @DateFormatString NVARCHAR(10) = ' 1 2020'
               DECLARE @NumericOne INT = 1
               DECLARE @DefaultValue DECIMAL(16,2) = 0.00
               DECLARE @AllowableCredit DECIMAL(16,2) = (SELECT TOP 1 CAST(Value AS DECIMAL(16,2)) FROM GlobalParameters WHERE Category = 'ETC' AND Name = 'AllowableCredit')

               CREATE TABLE #TaxDepEntityTemp
               (
                                 TaxDepEntityId BIGINT,
                                 DepreciationBeginDate DATE,
                                 DepreciationEndDate DATE,
                                 TerminationDate DATE,
                                 TaxDepTemplateId BIGINT NULL,
                                 TaxBasisAmount_Amount DECIMAL(16,2),
                                 TaxBasisAmount_Currency NVARCHAR(3),
                                 FXTaxBasisAmount_Amount DECIMAL(16,2),
                                 FXTaxBasisAmount_Currency NVARCHAR(3),
                                 ContractId BIGINT NULL,
                                 AssetId BIGINT NULL,
                                 LeaseAssetId BIGINT NULL,
                                 BlendedItemId BIGINT NULL,
                                 IsGLPosted BIT,
                                 IsComputationPending BIT,
                                 IsTaxDepreciationTerminated BIT,
                                 IsStraightLineMethodUsed BIT,
                                 IsConditionalSale BIT,
                                 IsRecoverOverFixedTerm BIT,   -- move to datacache : urvij
                                 LegalEntityId BIGINT NULL,
                                 EntityType NVARCHAR(28),
                                 ContractSequenceNumber NVARCHAR(80) NULL,
                                 BlendedItemName NVARCHAR(100) NULL,
                                 TaxDepDisposalGLTemplateId BIGINT NULL,
                                 TerminationFiscalYear INT NULL,
                                 InstrumentTypeId BIGINT NULL,
                                 LineOfBusinessId BIGINT NULL ,
                                 CostCenterId BIGINT NULL,
                                 CurrencyId BIGINT NULL,
                                 LeaseFinanceId BIGINT NULL,
                                 TaxProceedsAmount_Amount DECIMAL(16,2),
                                 TaxProceedsAmount_Currency NVARCHAR(3)
               );

               

               SELECT 
               taxDepEntity.Id TaxDepEntityId,
               taxDepEntity.DepreciationBeginDate,
               taxDepEntity.DepreciationEndDate,
               taxDepEntity.TerminationDate,
               taxDepEntity.TaxDepTemplateId,
               taxDepEntity.TaxBasisAmount_Amount,
               taxDepEntity.TaxBasisAmount_Currency,
               taxDepEntity.FXTaxBasisAmount_Amount,
               taxDepEntity.FXTaxBasisAmount_Currency,
               taxDepEntity.ContractId,
               taxDepEntity.AssetId,
               taxDepEntity.BlendedItemId,
               taxDepEntity.IsGLPosted,
               taxDepEntity.IsComputationPending,
               taxDepEntity.IsTaxDepreciationTerminated,
               taxDepEntity.IsStraightLineMethodUsed,
               taxDepEntity.IsConditionalSale,
               taxDepEntity.EntityType,
               CASE WHEN taxDepEntity.TaxDepTemplateId IS NOT NULL AND taxDepTemplate.RecoverOverFixedTerm = @True THEN @True ELSE @False END AS IsRecoverOverFixedTerm,
               taxDepEntity.TaxDepDisposalTemplateId,
               taxDepEntity.TaxProceedsAmount_Amount,
               taxDepEntity.TaxProceedsAmount_Currency
               INTO #FilteredTaxDepEntities
               FROM TaxDepEntities taxDepEntity
               JOIN TaxDepTemplates taxDepTemplate ON taxDepEntity.TaxDepTemplateId = taxDepTemplate.Id
               WHERE taxDepEntity.IsActive = @True AND taxDepEntity.IsComputationPending = @True 
               AND (((((@EntityType=@Asset AND taxDepEntity.AssetId IS NOT NULL) OR ((@EntityType=@Lease OR @EntityType = @Loan) AND taxDepEntity.ContractId IS NOT NULL)))
                                                            AND @FilterOption = @AllFilterOption)
                                                                                                         OR ((@EntityType = @Lease OR @EntityType = @Loan) AND @FilterOption = @OneFilterOption  AND taxDepEntity.ContractId = @ContractId)      
                                                                                                         OR (@EntityType = @Asset AND @FilterOption = @OneFilterOption  AND taxDepEntity.AssetId = @FromAssetId)
                                                                                                         OR (@EntityType = @Asset AND @FilterOption = @RangeFilterOption 
                                                                                                         AND taxDepEntity.AssetId >= @FromAssetId AND taxDepEntity.AssetId <= @ToAssetId))

               

               --Asset Location Details
               ;WITH AssetLocationCTE AS (
                              SELECT 
                              taxDepEntity.TaxDepEntityId,
                              country.ShortName,
                              ROW_NUMBER() OVER(PARTITION BY taxDepEntity.TaxDepEntityId ORDER BY assetLocation.EffectiveFromDate DESC, assetLocation.Id DESC) AS Rank_No
                              FROM #FilteredTaxDepEntities taxDepEntity 
                              JOIN Assets asset ON taxDepEntity.AssetId = asset.Id 
                              JOIN AssetLocations assetLocation ON asset.Id = assetLocation.AssetId 
                              JOIN Locations location ON assetLocation.LocationId = location.Id 
                              JOIN States state ON location.StateId = state.Id 
                              JOIN Countries country ON state.CountryId = Country.Id
                              WHERE assetLocation.IsActive = @True AND assetLocation.EffectiveFromDate <= taxDepEntity.DepreciationBeginDate
               )
               SELECT 
               TaxDepEntityId,
               CASE WHEN ShortName = 'USA' THEN @True ELSE @False END AS IsAssetCountryUSA,
               ShortName
               INTO #AssetLocationDetails
               FROM AssetLocationCTE where Rank_No = 1

               IF (@EntityType = @Lease)
               BEGIN
                              --Asset based TaxDepEntities for Leases
                              INSERT INTO #TaxDepEntityTemp
                              SELECT 
                                             taxDepEntity.TaxDepEntityId,
                                             taxDepEntity.DepreciationBeginDate,
                                             taxDepEntity.DepreciationEndDate,
                                             taxDepEntity.TerminationDate,
                                             taxDepEntity.TaxDepTemplateId,
                                             taxDepEntity.TaxBasisAmount_Amount,
                                             taxDepEntity.TaxBasisAmount_Currency,
                                             taxDepEntity.FXTaxBasisAmount_Amount,
                                             taxDepEntity.FXTaxBasisAmount_Currency,
                                             taxDepEntity.ContractId,
                                             taxDepEntity.AssetId,
                                             leaseAsset.Id LeaseAssetId,
                                             taxDepEntity.BlendedItemId,
                                             taxDepEntity.IsGLPosted,
                                             taxDepEntity.IsComputationPending,
                                             taxDepEntity.IsTaxDepreciationTerminated,
                                             taxDepEntity.IsStraightLineMethodUsed,
                                             taxDepEntity.IsConditionalSale,
                                             taxDepEntity.IsRecoverOverFixedTerm,
                                             leaseFinance.LegalEntityId,
                                             taxDepEntity.EntityType,
                                             contract.SequenceNumber ContractSequenceNumber,
                                             NULL BlendedItemName,
                                             taxDepEntity.TaxDepDisposalTemplateId,
                                             dbo.GetFiscalYear(legalEntity.TaxFiscalYearBeginMonthNo, taxDepEntity.TerminationDate) TerminationFiscalYear,
                                             leaseFinance.InstrumentTypeId,
                                             leaseFinance.LineofBusinessId,
                                             leaseFinance.CostCenterId,
                                             contract.CurrencyId,
                                             leaseFinance.Id LeaseFinanceId,
                       taxDepEntity.TaxProceedsAmount_Amount,
                       taxDepEntity.TaxProceedsAmount_Currency
                                             FROM #FilteredTaxDepEntities taxDepEntity
                                             JOIN Contracts contract ON taxDepEntity.ContractId = contract.Id AND taxDepEntity.EntityType = @Asset
                                             JOIN LeaseFinances leaseFinance ON taxDepEntity.ContractId = leaseFinance.ContractId AND leaseFinance.IsCurrent = @True
                                             JOIN LeaseAssets leaseAsset ON leaseFinance.Id = leaseAsset.LeaseFinanceId AND taxDepEntity.AssetId = leaseAsset.AssetId
                                             JOIN Assets asset ON leaseAsset.AssetId = asset.Id
                                             JOIN LegalEntities legalEntity ON legalEntity.Id = leaseFinance.LegalEntityId
                                             WHERE leaseFinance.BookingStatus != @Terminated AND taxDepEntity.BlendedItemId IS NULL
                                             AND asset.Status = @Inventory OR asset.Status = @Leased OR asset.Status = @Sold OR asset.Status = @Scrap OR asset.Status = @InvestorLeased
                              
                              -- combine lease assets and lease blended items query into 1 : Simran

                              --BlendedItem based TaxDepEntities for Leases
                              INSERT INTO #TaxDepEntityTemp
                              SELECT 
                                             taxDepEntity.TaxDepEntityId,
                                             taxDepEntity.DepreciationBeginDate,
                                             taxDepEntity.DepreciationEndDate,
                                             taxDepEntity.TerminationDate,
                                             taxDepEntity.TaxDepTemplateId,
                                             taxDepEntity.TaxBasisAmount_Amount,
                                             taxDepEntity.TaxBasisAmount_Currency,
                                             taxDepEntity.FXTaxBasisAmount_Amount,
                                             taxDepEntity.FXTaxBasisAmount_Currency,
                                             taxDepEntity.ContractId,
                                             taxDepEntity.AssetId,
                                             NULL,
                                             taxDepEntity.BlendedItemId,
                                             taxDepEntity.IsGLPosted,
                                             taxDepEntity.IsComputationPending,
                                             taxDepEntity.IsTaxDepreciationTerminated,
                                             taxDepEntity.IsStraightLineMethodUsed,
                                             taxDepEntity.IsConditionalSale,
                                             taxDepEntity.IsRecoverOverFixedTerm,
                                             leaseFinance.LegalEntityId,
                                             taxDepEntity.EntityType,
                                             contract.SequenceNumber ContractSequenceNumber,
                                             blendedItem.Name BlendedItemName,
                                             taxDepEntity.TaxDepDisposalTemplateId,
                                             dbo.GetFiscalYear(legalEntity.TaxFiscalYearBeginMonthNo, taxDepEntity.TerminationDate) TerminationFiscalYear,
                                             leaseFinance.InstrumentTypeId,
                                             leaseFinance.LineofBusinessId,
                                             leaseFinance.CostCenterId,
                                             contract.CurrencyId,
                                             leaseFinance.Id LeaseFinanceId,
                       taxDepEntity.TaxProceedsAmount_Amount,
                       taxDepEntity.TaxProceedsAmount_Currency
                                             FROM #FilteredTaxDepEntities taxDepEntity
                                             JOIN Contracts contract ON taxDepEntity.ContractId = contract.Id AND taxDepEntity.EntityType = @BlendedItem
                                             JOIN LeaseFinances leaseFinance ON taxDepEntity.ContractId = leaseFinance.ContractId AND leaseFinance.IsCurrent = @True
                                             JOIN BlendedItems blendedItem ON taxDepEntity.BlendedItemId = blendedItem.Id
                                             JOIN LegalEntities legalEntity ON legalEntity.Id = leaseFinance.LegalEntityId
                                             WHERE leaseFinance.BookingStatus != @Terminated AND taxDepEntity.BlendedItemId IS NOT NULL
                                             AND contract.Status = @Commenced

               END

               ELSE IF (@EntityType = @Loan)
               BEGIN
                              --BlendedItem based TaxDepEntities for Loans
                              INSERT INTO #TaxDepEntityTemp
                              SELECT 
                                             taxDepEntity.TaxDepEntityId,
                                             taxDepEntity.DepreciationBeginDate,
                                             taxDepEntity.DepreciationEndDate,
                                             taxDepEntity.TerminationDate,
                                             taxDepEntity.TaxDepTemplateId,
                                             taxDepEntity.TaxBasisAmount_Amount,
                                             taxDepEntity.TaxBasisAmount_Currency,
                                             taxDepEntity.FXTaxBasisAmount_Amount,
                                             taxDepEntity.FXTaxBasisAmount_Currency,
                                             taxDepEntity.ContractId,
                                             NULL,
                                             NULL,
                                             taxDepEntity.BlendedItemId,
                                             taxDepEntity.IsGLPosted,
                                             taxDepEntity.IsComputationPending,
                                             taxDepEntity.IsTaxDepreciationTerminated,
                                             taxDepEntity.IsStraightLineMethodUsed,
                                             taxDepEntity.IsConditionalSale,
                                             taxDepEntity.IsRecoverOverFixedTerm,
                                             loanFinance.LegalEntityId,
                                             taxDepEntity.EntityType,
                                             NULL ContractSequenceNumber,
                                             blendedItem.Name BlendedItemName,
                                             taxDepEntity.TaxDepDisposalTemplateId,
                                             dbo.GetFiscalYear(legalEntity.TaxFiscalYearBeginMonthNo, taxDepEntity.TerminationDate) TerminationFiscalYear,
                                             NULL,
                                             NULL,
                                             NULL,
                                             NULL,
                                             NULL,
                       taxDepEntity.TaxProceedsAmount_Amount,
                       taxDepEntity.TaxProceedsAmount_Currency
                                             FROM #FilteredTaxDepEntities taxDepEntity
                                             JOIN LoanFinances loanFinance ON taxDepEntity.ContractId = loanFinance.ContractId AND loanFinance.IsCurrent = @True AND taxDepEntity.EntityType = @BlendedItem
                                             JOIN BlendedItems blendedItem ON taxDepEntity.BlendedItemId = blendedItem.Id
                                             JOIN LegalEntities legalEntity ON legalEntity.Id = loanFinance.LegalEntityId
                                             WHERE loanFinance.Status != @Terminated AND loanFinance.Status = @Commenced
               END

               ELSE
               BEGIN
                              --TaxDepEntities for Assets
                              INSERT INTO #TaxDepEntityTemp
                              SELECT 
                                             taxDepEntity.TaxDepEntityId,
                                             taxDepEntity.DepreciationBeginDate,
                                             taxDepEntity.DepreciationEndDate,
                                             taxDepEntity.TerminationDate,
                                             taxDepEntity.TaxDepTemplateId,
                                             taxDepEntity.TaxBasisAmount_Amount,
                                             taxDepEntity.TaxBasisAmount_Currency,
                                             taxDepEntity.FXTaxBasisAmount_Amount,
                                             taxDepEntity.FXTaxBasisAmount_Currency,
                                             taxDepEntity.ContractId,
                                             taxDepEntity.AssetId,
                                             leaseAsset.Id LeaseAssetId,
                                             NULL,
                                             taxDepEntity.IsGLPosted,
                                             taxDepEntity.IsComputationPending,
                                             taxDepEntity.IsTaxDepreciationTerminated,
                                             taxDepEntity.IsStraightLineMethodUsed,
                                             taxDepEntity.IsConditionalSale,
                                             taxDepEntity.IsRecoverOverFixedTerm,
                                             asset.LegalEntityId,
                                             taxDepEntity.EntityType,
                                             contract.SequenceNumber ContractSequenceNumber,
                                             NULL BlendedItemName,
                                             taxDepEntity.TaxDepDisposalTemplateId,
                                             dbo.GetFiscalYear(legalEntity.TaxFiscalYearBeginMonthNo, taxDepEntity.TerminationDate) TerminationFiscalYear,
                                             leaseFinance.InstrumentTypeId,
                                             leaseFinance.LineofBusinessId,
                                             leaseFinance.CostCenterId,
                                             contract.CurrencyId,
                                             leaseFinance.Id LeaseFinanceId,
                       taxDepEntity.TaxProceedsAmount_Amount,
                       taxDepEntity.TaxProceedsAmount_Currency
                                             FROM #FilteredTaxDepEntities taxDepEntity
                                             JOIN Assets asset ON taxDepEntity.AssetId = asset.Id AND taxDepEntity.EntityType = @Asset
                                             JOIN LegalEntities legalEntity ON asset.LegalEntityId = legalEntity.Id
                                             LEFT JOIN Contracts contract ON taxDepEntity.ContractId = contract.Id AND taxDepEntity.ContractId IS NOT NULL
                                             LEFT JOIN LeaseFinances leaseFinance ON taxDepEntity.ContractId = leaseFinance.ContractId AND leaseFinance.IsCurrent = @True AND taxDepEntity.ContractId IS NOT NULL
                                             LEFT JOIN LeaseAssets leaseAsset ON leaseFinance.Id = leaseAsset.LeaseFinanceId AND taxDepEntity.AssetId = leaseAsset.AssetId AND leaseFinance.Id IS NOT NULL
                                             WHERE (asset.Status = @Inventory 
                                             OR asset.Status = @Leased 
                                             OR asset.Status = @Sold 
                                             OR asset.Status = @Scrap
                                             OR asset.Status = @InvestorLeased)
                                             AND (leaseFinance.Id IS NULL OR leaseFinance.BookingStatus != @Terminated)
                                             AND @EntityType = @Asset
               END

               --Fetch details for CurrentLeaseFinanceId 
               SELECT
                   taxDepEntityTemp.TaxDepEntityId,
                              InstrumentTypeId = taxDepEntityTemp.InstrumentTypeId,
                              LineOfBusinessId = taxDepEntityTemp.LineOfBusinessId,
                              CostCenterId = taxDepEntityTemp.CostCenterId,
                              ContractCurrencyISO = code.ISO,
                              TaxAssetSetupGLTemplateId = CASE WHEN LFD.TaxAssetSetupGLTemplateId IS NOT NULL 
									                      THEN LFD.TaxAssetSetupGLTemplateId 
									                      ELSE  LFDS.TaxAssetSetupGLTemplateId 										
									                      END,
		                      TaxDepExpenseGLTemplateId = CASE WHEN LFD.TaxDepExpenseGLTemplateId IS NOT NULL 
									                      THEN LFD.TaxDepExpenseGLTemplateId 
									                      ELSE LFDS.TaxDepExpenseGLTemplateId 
									                      END,       
							  CurrentTaxAssetSetupGLTemplateId = LFD.TaxAssetSetupGLTemplateId,
                              CurrentTaxDepExpenseGLTemplateId = LFD.TaxDepExpenseGLTemplateId,
                              Row_Num = ROW_NUMBER() OVER (PARTITION BY taxDepEntityTemp.TaxDepEntityId ORDER BY LA.AmendmentDate, LA.Id  DESC)
               INTO #TaxDepTemplatesInfo
               FROM #TaxDepEntityTemp taxDepEntityTemp     
               JOIN Currencies cur ON taxDepEntityTemp.CurrencyId = cur.Id
               JOIN CurrencyCodes code ON cur.CurrencyCodeId = code.Id         
    JOIN LeaseFinanceDetails LFD ON taxDepEntityTemp.LeaseFinanceId = LFD.Id
               LEFT JOIN LeaseAmendments LA ON taxDepEntityTemp.LeaseFinanceId = LA.CurrentLeaseFinanceId 
               LEFT JOIN LeaseFinanceDetails LFDS ON LFDS.Id = LA.OriginalLeaseFinanceId
-- DO Union instead of left join  : Simran


               SELECT
                              TaxDepEntityId,
                              InstrumentTypeId,
                              LineOfBusinessId,
                              CostCenterId,
                              ContractCurrencyISO,
                              TaxDepExpenseGLTemplateId,
                              TaxAssetSetupGLTemplateId,
                              CurrentTaxAssetSetupGLTemplateId,
                              CurrentTaxDepExpenseGLTemplateId
               INTO #TaxDepGlTemplateInfo
               FROM #TaxDepTemplatesInfo
               where Row_Num = 1

               
               --ETCBlendedItemDetails (TODO: URVIJ - to be reviewed [Can avoid Repititive Joins])
               SELECT 
               taxDepEntityTemp.TaxDepEntityId,
               blendedItem.TaxCreditTaxBasisPercentage EtcBlendedItemTaxCreditTaxBasisPercentage
               INTO #EtcBlendedItemTaxCreditTaxBasisPercentageDetail
               FROM LeaseAssets leaseAsset
               JOIN BlendedItemAssets blendedItemAsset ON leaseAsset.Id = blendedItemAsset.LeaseAssetId AND blendedItemAsset.IsActive = @True
               JOIN BlendedItems blendedItem ON blendedItemAsset.BlendedItemId = blendedItem.Id AND blendedItem.IsActive = @True AND blendedItem.IsETC = @True
               JOIN #TaxDepEntityTemp taxDepEntityTemp on leaseAsset.LeaseFinanceId = taxDepEntityTemp.LeaseFinanceId AND leaseAsset.AssetId = taxDepEntityTemp.AssetId AND leaseAsset.IsActive = @True


               INSERT INTO TaxDepAmortJobExtracts
                              (TaxDepEntityId
               , TaxDepAmortizationId
               , DepreciationBeginDate
               , DepreciationEndDate
                 ,TerminationDate
               , TaxDepTemplateId
               , TaxBasisAmount_Amount
               , TaxBasisAmount_Currency
               , FXTaxBasisAmount_Amount
               , FXTaxBasisAmount_Currency
               , ContractId
               , AssetId
               , LeaseAssetId
               , BlendedItemId
               , LegalEntityId
               , GLFinancialOpenPeriodFromDate
               , EtcBlendedItemTaxCreditTaxBasisPercentage
               , AllowableCredit
               , FiscalYearBeginMonth
               , FiscalYearEndMonth
               , IsGLPosted
               , IsComputationPending
               , IsAssetCountryUSA
               , IsRecoverOverFixedTerm 
                , IsTaxDepreciationTerminated
               , IsStraightLineMethodUsed
               , IsConditionalSale
               , EntityType
               , ContractSequenceNumber
               , BlendedItemName        
               , TaxDepDisposalGLTemplateId
               , TaxAssetSetupGLTemplateId
               , TaxDepExpenseGLTemplateId
               , CurrentTaxAssetSetupGLTemplateId
               , CurrentTaxDepExpenseGLTemplateId
               , ContractCurrencyISO
               , InstrumentTypeId
               , LineOfBusinessId
               , CostCenterId
                 ,TerminationFiscalYear
                 ,TaxProceedsAmount_Amount
                 ,TaxProceedsAmount_Currency
               , JobStepInstanceId
               , TaskChunkServiceInstanceId
               , IsSubmitted
			   , ReversalPostDate
               , CreatedById
               , CreatedTime
               , UpdatedById
               , UpdatedTime)

               SELECT 
                  taxDepEntityTemp.TaxDepEntityId
               , taxDepAmortization.Id as TaxDepAmortizationId
               , taxDepEntityTemp.DepreciationBeginDate
               , taxDepEntityTemp.DepreciationEndDate
               , taxDepEntityTemp.TerminationDate
               , taxDepEntityTemp.TaxDepTemplateId
               , taxDepEntityTemp.TaxBasisAmount_Amount
               , taxDepEntityTemp.TaxBasisAmount_Currency
               , taxDepEntityTemp.FXTaxBasisAmount_Amount
               , taxDepEntityTemp.FXTaxBasisAmount_Currency
               , taxDepEntityTemp.ContractId
               , taxDepEntityTemp.AssetId
               , taxDepEntityTemp.LeaseAssetId
               , taxDepEntityTemp.BlendedItemId
               , taxDepEntityTemp.LegalEntityId
               , glOpenPeriods.FromDate
               , etcBlendedItem.EtcBlendedItemTaxCreditTaxBasisPercentage
               , @AllowableCredit
               , MONTH(CAST((legalEntity.TaxFiscalYearBeginMonthNo + @DateFormatString) AS DATETIME)) AS FiscalYearBeginMonth
               , CASE WHEN TaxFiscalYearBeginMonthNo = @December THEN @NumericOne ELSE (MONTH(CAST((legalEntity.TaxFiscalYearBeginMonthNo + @DateFormatString) AS DATETIME)) - @NumericOne) END AS FiscalYearEndMonth
               , taxDepEntityTemp.IsGLPosted
               , taxDepEntityTemp.IsComputationPending
               , CASE WHEN assetLocationDetail.IsAssetCountryUSA IS NULL THEN @False ELSE assetLocationDetail.IsAssetCountryUSA END
               , taxDepEntityTemp.IsRecoverOverFixedTerm
               , taxDepEntityTemp.IsTaxDepreciationTerminated
               , taxDepEntityTemp.IsStraightLineMethodUsed
               , taxDepEntityTemp.IsConditionalSale
               , taxDepEntityTemp.EntityType
               , taxDepEntityTemp.ContractSequenceNumber
               , taxDepEntityTemp.BlendedItemName
               , taxDepEntityTemp.TaxDepDisposalGLTemplateId
               , GlTemplateInfo.TaxAssetSetupGLTemplateId
               , GlTemplateInfo.TaxDepExpenseGLTemplateId
               , GlTemplateInfo.CurrentTaxAssetSetupGLTemplateId
               , GlTemplateInfo.CurrentTaxDepExpenseGLTemplateId
               , GlTemplateInfo.ContractCurrencyISO
               , GlTemplateInfo.InstrumentTypeId
               , GlTemplateInfo.LineOfBusinessId
               , GlTemplateInfo.CostCenterId
                 ,taxDepEntityTemp.TerminationFiscalYear
               ,taxDepEntityTemp.TaxProceedsAmount_Amount
               ,taxDepEntityTemp.TaxProceedsAmount_Currency
               , @JobStepInstanceId
               , NULL
               , @False
			   , @ReversalPostDate
               , @CreatedById
               , @CreatedTime
               , NULL
               , NULL
               FROM #TaxDepEntityTemp taxDepEntityTemp
               JOIN @ValidLegalEntityIds validLegalEntity ON taxDepEntityTemp.LegalEntityId = validLegalEntity.Id
               JOIN LegalEntities legalEntity ON taxDepEntityTemp.LegalEntityId = legalEntity.Id
               JOIN GLFinancialOpenPeriods glOpenPeriods ON taxDepEntityTemp.LegalEntityId = glOpenPeriods.LegalEntityId AND glOpenPeriods.IsCurrent = @True
               LEFT JOIN #AssetLocationDetails assetLocationDetail ON taxDepEntityTemp.TaxDepEntityId = assetLocationDetail.TaxDepEntityId AND assetLocationDetail.TaxDepEntityId IS NOT NULL
               LEFT JOIN #EtcBlendedItemTaxCreditTaxBasisPercentageDetail etcBlendedItem ON taxDepEntityTemp.AssetId IS NOT NULL AND taxDepEntityTemp.TaxDepEntityId = etcBlendedItem.TaxDepEntityId AND etcBlendedItem.TaxDepEntityId IS NOT NULL
               LEFT JOIN TaxDepAmortizations taxDepAmortization ON taxDepEntityTemp.TaxDepEntityId = taxDepAmortization.TaxDepEntityId AND taxDepAmortization.IsActive = @True AND taxDepAmortization.IsTaxDepreciationTerminated = @False
               LEFT JOIN #TaxDepGlTemplateInfo GlTemplateInfo ON taxDepEntityTemp.TaxDepEntityId = GlTemplateInfo.TaxDepEntityId
                              
               IF OBJECT_ID('tempDB..#FilteredTaxDepEntities') IS NOT NULL
                              DROP TABLE #FilteredTaxDepEntities
               IF OBJECT_ID('tempDB..#TaxDepEntityTemp') IS NOT NULL
                              DROP TABLE #TaxDepEntityTemp
               IF OBJECT_ID('tempDB..#AssetLocationDetails') IS NOT NULL
                              DROP TABLE #AssetLocationDetails
               IF OBJECT_ID('tempDB..#EtcBlendedItemTaxCreditTaxBasisPercentageDetail') IS NOT NULL
                              DROP TABLE #EtcBlendedItemTaxCreditTaxBasisPercentageDetail
               IF OBJECT_ID('tempDB..#TaxDepTemplatesInfo') IS NOT NULL
                              DROP TABLE #TaxDepTemplatesInfo
               IF OBJECT_ID('tempDB..#TaxDepGlTemplateInfo') IS NOT NULL
                              DROP TABLE #TaxDepGlTemplateInfo
END

GO
