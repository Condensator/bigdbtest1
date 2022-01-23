SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE PROC [dbo].[PopulatePropertyTaxExportJobExtract]
(
    @CreatedById BIGINT,
    @CreatedTime DATETIMEOFFSET,
    @JobStepInstanceId BIGINT,
	@TaskChunkServiceInstanceId BIGINT = NULL,	
    @ValidLegalEntityIds IdList READONLY,
	@EligibleStates PropertyTaxExportEligibleStateSettingsForJobExtract READONLY,
	@UpdateRunDate Date,  	
    @CurrentPortfolioId BIGINT,
	@BatchSize BIGINT
)
AS
	BEGIN
	SET NOCOUNT ON  
	SET ANSI_WARNINGS OFF
		IF OBJECT_ID('tempDB..#ValidAssetLocations') IS NOT NULL
			DROP TABLE #ValidAssetLocations
		IF OBJECT_ID('tempDB..#HistoricalAssetData') IS NOT NULL
			DROP TABLE #HistoricalAssetData			
		IF OBJECT_ID('tempDB..#tempTable2') IS NOT NULL
			DROP TABLE #tempTable2	
		IF OBJECT_ID('tempDB..#tempTable3') IS NOT NULL
			DROP TABLE #tempTable3	
		IF OBJECT_ID('tempDB..#AsOfDateAssetHistoryData') IS NOT NULL
			DROP TABLE #AsOfDateAssetHistoryData 
		CREATE TABLE #ValidAssetLocations
		(
			AssetId BIGINT NULL,
			AssetLocationId BIGINT NULL,
			LocationId BIGINT NULL,
			EffectiveFromDate DATE NULL,
			StateCode NVARCHAR(20) NULL ,
			AssetLocationStateId BIGINT NULL
		)
		CREATE TABLE #HistoricalAssetData
		(
			AssetHistoryId BIGINT NULL, 
			AssetId BIGINT NULL, 
			AsOfDate DATE NULL,
			SourceModule NVARCHAR(50) NULL, 
			ContractId BIGINT NULL,
			AssetStatus NVARCHAR(20) NULL, 
			FinancialType NVARCHAR(30) NULL, 
			PropertyTaxReportCodeId BIGINT NULL, 
			ContractIdRowNumber BIGINT NULL,
			PrevContractId BIGINT NULL, 
			PreviousLeaseNumber NVARCHAR(40) NULL,
			InventoryRowNumber  BIGINT NULL,
			RowNumber BIGINT NULL
		)
		CREATE TABLE #AsOfDateAssetHistoryData
		(
			AssetHistoryId BIGINT NULL, 
			AssetId BIGINT NULL, 
			AsOfDate DATE NULL,
			SourceModule NVARCHAR(50) NULL, 
			ContractId BIGINT NULL,
			AssetStatus NVARCHAR(20) NULL, 
			FinancialType NVARCHAR(30) NULL, 
			PropertyTaxReportCodeId BIGINT NULL, 
			ContractIdRowNumber BIGINT NULL,
			PrevContractId BIGINT NULL, 
			PreviousLeaseNumber NVARCHAR(40) NULL,
			InventoryRowNumber  BIGINT NULL,
			RowNumber BIGINT NULL,			
		)
		CREATE INDEX AsOfDateAssetHistoryData_Asset ON #AsOfDateAssetHistoryData (AssetId)
		CREATE INDEX AsOfDateAssetHistoryData_Contract ON #AsOfDateAssetHistoryData (ContractId)
		CREATE TABLE #tempTable2
		(
			AssetId BIGINT NULL,
			LeaseContractType NVARCHAR(40) NULL,
			ContractSyndicationType NVARCHAR(40) NULL,
			ContractOriginationSourceType NVARCHAR(40) NULL,
			PropertyTaxResponsibility NVARCHAR(40) NULL,
			IsFederalIncomeTaxExempt BIT NULL,
			BankQualified NVARCHAR(40) NULL,
			ContractId BIGINT NULL,
			ContractOriginationId BIGINT NULL,
			IsContractOriginationServiced BIT NULL,
			IsSyndicationResponsibilityRemitOnly BIT NULL
		)
		CREATE TABLE #tempTable3
		(
			AssetId BIGINT NULL
			,TypeId	BIGINT	 NULL	
			,AssetCategoryId BIGINT NULL
			,ManufacturerId BIGINT NULL
			,CustomerId BIGINT NULL
			,LegalEntityId BIGINT NULL
			,Alias NVARCHAR(200) NULL	 		
			,[Description] NVARCHAR(500) NULL
			,AcquisitionDate DATE NULL  
			,SerialNumber NVARCHAR(200) NULL
			,ModelYear Decimal(4,0) NULL
			,IsEligibleForPropertyTax BIT NULL
			,PropertyTaxCost_Amount DECIMAL(16,2) NULL
			,PropertyTaxCost_Currency NVARCHAR(10) NULL
			,AssetCatalogId BIGINT NULL
			,ProductId BIGINT NULL
			,InServiceDate DATE NULL
			,AssetUsageCondition NVARCHAR(200) NULL  
			,SubStatus NVARCHAR(50) NULL
			,PropertyTaxReportCode NVARCHAR(50) NULL
			,FinancialType NVARCHAR(30) NULL
			,AssetStatus NVARCHAR(50) NULL
			,AssetClassCode NVARCHAR(50) NULL
			,DisposedDate DATE NULL
			,AsOfDate DATE NULL
			,SourceModule NVARCHAR(50) NULL
			,PreviousLeaseNumber NVARCHAR(100) NULL
		)
		CREATE TABLE #AssetLocationEffectiveDateTemp
		(
			AssetId BIGINT,
			EffectiveFromDate DATE,
			StateCode NVARCHAR(25),
			AssetLocationStateId BIGINT,
			AssetLocationId BIGINT,
			RowNumber INT
		)

		CREATE TABLE #AssetLocationEffectiveDates
		(
			AssetId BIGINT,
			EffectiveFromDate DATE,
			StateCode NVARCHAR(25),
			AssetLocationStateId BIGINT,
			AssetLocationId BIGINT
		)

		CREATE TABLE #AssetLocationEffectiveToDate
		(
			AssetId BIGINT,
			EffectiveFromDate DATE,
			EffectiveToDate DATE,
			StateCode NVARCHAR(25),
			AssetLocationStateId BIGINT,
			AssetLocationId BIGINT,
			IsIncuded INT
		)

		CREATE TABLE #EligibleAssetTemp
		(
			AssetId BIGINT,
			IsAssetEligible INT,
			EffectiveFromDate DATE,
			StateCode NVARCHAR(25),
			AssetLocationStateId BIGINT,
			AssetLocationId BIGINT
		)

		CREATE TABLE #EligibleAssets
		(
			AssetId BIGINT,
			EffectiveFromDate DATE,
			StateCode NVARCHAR(25),
			AssetLocationStateId BIGINT,
			AssetLocationId BIGINT
		)

		SELECT * INTO #EligibleStates FROM @EligibleStates
	
		DECLARE @Start INT = 1
		DECLARE @End INT, 
		@maxAssetId INT = (SELECT MAX(Id) from Assets)

		WHILE @Start <= @maxAssetId
		BEGIN   -- Chunking 

			IF @maxAssetId > @BatchSize  
				SET @End = @Start + @BatchSize - 1 
			ELSE
				SET @End = 	@maxAssetId


			-- Getting the active asset locations
			INSERT INTO #ValidAssetLocations
			SELECT AssetLocation.AssetId, AssetLocation.Id AssetLocationId, AssetLocation.LocationId, AssetLocation.EffectiveFromDate    
				,State.ShortName StateCode, Location.StateId AssetLocationStateId    
			FROM AssetLocations AssetLocation 
				INNER JOIN Locations Location ON Location.Id = AssetLocation.LocationId
				INNER JOIN States State ON State.Id = Location.StateId
			WHERE AssetLocation.IsActive=1 
					AND Location.ApprovalStatus IN ('Approved', 'ReAssess')
					AND Location.IsActive = 1    
					AND AssetLocation.AssetId BETWEEN @Start AND @End
			
			
			INSERT INTO #HistoricalAssetData
			SELECT t1.Id AssetHistoryId, t1.AssetId, t1.AsOfDate,SourceModule, Contractid,Status AssetStatus, 
							FinancialType, PropertyTaxReportCodeId, 
							(CAST(1 as bigint)) ContractIdRowNumber, 
							(CAST(0 as bigint)) PrevContractId, 
							(CAST(null as nvarchar(40))) PreviousLeaseNumber,
							(CAST(1 as bigint)) InventoryRowNumber,
							row_number() over(partition by t1.AssetId order by t1.AsOfDate desc, t1.Id desc) rowNumber						
			FROM AssetHistories t1 
			JOIN #ValidAssetLocations AssetLocation ON t1.AssetId = AssetLocation.AssetId
			JOIN #EligibleStates EligibleState ON AssetLocation.AssetLocationStateId = EligibleState.StateId
			WHERE t1.Reason <> 'AssetSerialNumberChange'
				AND t1.AsOfDate <= EligibleState.AssessmentDate


			-- This block will identify assets those are scrap due AssetSplit and will be removed from further processing
			DECLARE @SplittedAssetIds TABLE (Id BIGINT)
			INSERT INTO @SplittedAssetIds
			SELECT AssetId FROM AssetHistories WHERE AssetId IN (Select AssetId FROM #HistoricalAssetData) AND Status = 'Scrap' AND SourceModule = 'AssetSplit'

			DELETE FROM #HistoricalAssetData WHERE AssetId IN (SELECT Id FROM @SplittedAssetIds) -- Removing AssetSplits 


			---- Setting the check point as Inventory record, beyond this record we should not take data for ContractId
			UPDATE historicalData SET historicalData.InventoryRowNumber = (SELECT TOP 1 innerTemp1.rowNumber 
																		  FROM #HistoricalAssetData innerTemp1 
																		  WHERE innerTemp1.AssetId = historicalData.AssetId 
																			AND innerTemp1.AssetStatus IN ('Inventory','Investor') 
																			AND innerTemp1.rowNumber >= historicalData.rowNumber
																		  ORDER BY rowNumber)																
			FROM #HistoricalAssetData historicalData WHERE rowNumber = 1	



			-- This is to obtain ContractId if incase it is not available in the latest record
			-- There will be a little performance overhead only for the asset which don't have valid ContractId
			-- Once AssetHistory issues are resolved, this should not cause any overhead and we can remove this block
			UPDATE historicalData SET historicalData.ContractId = temp.ContractId, ContractIdRowNumber = temp.rowNumber			
			FROM #HistoricalAssetData historicalData
				INNER JOIN #HistoricalAssetData temp ON historicalData.AssetId = temp.AssetId 					
						AND temp.rowNumber = 
						(SELECT TOP 1 innerTemp.rowNumber 
						 FROM #HistoricalAssetData innerTemp
						 WHERE historicalData.AssetId = innerTemp.AssetId 
								AND innerTemp.ContractId IS NOT NULL 					
								AND innerTemp.AssetStatus NOT IN ('Inventory','Investor')						
								AND innerTemp.rowNumber > 1		
								AND innerTemp.rowNumber > historicalData.rowNumber
								AND innerTemp.rowNumber < historicalData.InventoryRowNumber
						ORDER BY rowNumber		
						)									
			WHERE historicalData.rowNumber = 1 AND historicalData.ContractId IS NULL AND historicalData.AssetStatus NOT IN ('Inventory','Investor') 



			-- making a self join to obtain the previous contractId from the other records of the same asset
			-- Attemp : 1 To get the previous contractId which is not equals to current ContractId
			UPDATE historicalData SET historicalData.PrevContractId = temp.ContractId
			FROM #HistoricalAssetData historicalData
				INNER JOIN #HistoricalAssetData temp ON historicalData.AssetId = temp.AssetId 					
						AND temp.rowNumber = 
						(SELECT TOP 1 innerTemp.rowNumber 
						FROM #HistoricalAssetData innerTemp
						WHERE historicalData.AssetId = innerTemp.AssetId 
							AND innerTemp.ContractId IS NOT NULL 					
							AND innerTemp.AssetStatus NOT IN ('Inventory','Investor')					
							AND innerTemp.rowNumber > historicalData.ContractIdRowNumber
							--AND innerTemp.rowNumber > 1  -- Already covered		
							AND innerTemp.rowNumber > historicalData.rowNumber							
							AND (historicalData.ContractId IS NULL OR historicalData.ContractId != innerTemp.ContractId) 
						ORDER BY rowNumber
						)							
			WHERE temp.ContractId IS NOT NULL AND historicalData.rowNumber = 1 		



			INSERT INTO #AsOfDateAssetHistoryData
			SELECT *
			--AssetHistoryId, AssetId, AsOfDate, SourceModule, ContractId,AssetStatus, FinancialType,PropertyTaxReportCodeId
			FROM #HistoricalAssetData
			WHERE rowNumber = 1		


			-- Updating Previous Lease Number 
			UPDATE historicalData SET historicalData.PreviousLeaseNumber = Contract.SequenceNumber
			FROM #AsOfDateAssetHistoryData historicalData
				INNER JOIN Contracts Contract ON Contract.Id = historicalData.PrevContractId
			--WHERE historicalData.PrevContractId IS NOT NULL AND historicalData.PrevContractId != 0




			INSERT INTO #tempTable2
			SELECT
				LeasedAssetData.AssetId	
				,LeaseFinanceDetail.LeaseContractType
				,Contract.SyndicationType ContractSyndicationType
				,OriginationSourceType.Name ContractOriginationSourceType
				,LeaseFinance.PropertyTaxResponsibility 
				,LeaseFinance.IsFederalIncomeTaxExempt
				,LeaseFinance.BankQualified
				,LeaseFinance.ContractId
				,ContractOrigination.Id ContractOriginationId
				,(SELECT TOP 1 ServicingDetail.IsServiced FROM ContractOriginationServicingDetails ContractOriginationServicingDetail
					JOIN ServicingDetails ServicingDetail ON ServicingDetail.Id = ContractOriginationServicingDetail.ServicingDetailId
					WHERE ServicingDetail.IsActive = 1 AND ContractOriginationServicingDetail.ContractOriginationId= ContractOrigination.Id
					AND ServicingDetail.EffectiveDate < @UpdateRunDate ORDER BY ServicingDetail.EffectiveDate DESC
					)
					IsContractOriginationServiced
            
				,(CASE WHEN EXISTS(SELECT t.IsServiced FROM (SELECT TOP 1 ReceivableForTransferServicings.IsServiced,ReceivableForTransferServicings.PropertyTaxResponsibility FROM ReceivableForTransfers 
					JOIN ReceivableForTransferServicings ON ReceivableForTransfers.Id = ReceivableForTransferServicings.ReceivableForTransferId
					WHERE ReceivableForTransfers.ContractId = LeaseFinance.ContractId AND ReceivableForTransfers.ApprovalStatus != 'Inactive'
							AND ReceivableForTransferServicings.IsActive = 1 AND ReceivableForTransferServicings.EffectiveDate <= @UpdateRunDate
							order by ReceivableForTransferServicings.EffectiveDate desc) t where 
							t.PropertyTaxResponsibility = 'RemitOnly' AND t.IsServiced=1
							) THEN 1 ELSE 0 END) IsSyndicationResponsibilityRemitOnly 
			FROM #AsOfDateAssetHistoryData LeasedAssetData
				JOIN LeaseFinances LeaseFinance ON LeaseFinance.ContractId = LeasedAssetData.ContractId AND LeaseFinance.IsCurrent = 1
				JOIN LeaseFinanceDetails LeaseFinanceDetail ON LeaseFinanceDetail.Id= LeaseFinance.Id
				JOIN Contracts Contract ON Contract.Id= LeaseFinance.ContractId
				JOIN ContractOriginations ContractOrigination ON ContractOrigination.Id= LeaseFinance.ContractOriginationId
				JOIN OriginationSourceTypes OriginationSourceType ON OriginationSourceType.Id= ContractOrigination.OriginationSourceTypeId        			
			WHERE LeasedAssetData.ContractId IS NOT NULL
			--LeaseAsset.AssetId BETWEEN @assetMinId AND @assetMaxId AND LeaseAsset.IsActive = 1 

			INSERT INTO #tempTable3
			SELECT				
				 Asset.Id AssetId
				,Asset.TypeId			
				,Asset.AssetCategoryId
				,Asset.ManufacturerId
				,Asset.CustomerId
				,Asset.LegalEntityId
				,Asset.Alias			
				,Asset.Description
				,Asset.AcquisitionDate    
				,null as SerialNumber
				,Asset.ModelYear
				,Asset.IsEligibleForPropertyTax
				,Asset.PropertyTaxCost_Amount
				,Asset.PropertyTaxCost_Currency
				,Asset.AssetCatalogId
				,Asset.ProductId
				,Asset.InServiceDate
				,Asset.UsageCondition AssetUsageCondition  
				,Asset.SubStatus
				,(Select PTRCC.Code FROM PropertyTaxReportCodeConfigs PTRCC WHERE PTRCC.Id = LatestAssetHistory.PropertyTaxReportCodeId) PropertyTaxReportCode
				,Asset.FinancialType
				,LatestAssetHistory.AssetStatus
				,AssetClassCode.ClassCode AssetClassCode  
				,Asset.DisposedDate
				,LatestAssetHistory.AsOfDate
				,LatestAssetHistory.SourceModule
				,LatestAssetHistory.PreviousLeaseNumber
			FROM Assets Asset             
			 INNER JOIN #AsOfDateAssetHistoryData LatestAssetHistory ON Asset.Id = LatestAssetHistory.AssetId             
			 INNER JOIN AssetTypes AssetType ON Asset.TypeId = AssetType.Id
			 LEFT JOIN AssetClassCodes AssetClassCode ON AssetType.AssetClassCodeId = AssetClassCode.Id        
			WHERE Asset.LegalEntityId IN (Select * from @ValidLegalEntityIds)

			INSERT INTO #AssetLocationEffectiveToDate
			SELECT 
				AssetId = Asset.AssetId,
				EffectiveFromDate = LatestLocation.EffectiveFromDate ,
				EffectiveToDate = CASE WHEN AssetLocationTo.EffectiveFromDate <= EligibleState.AssessmentDate THEN AssetLocationTo.EffectiveFromDate ELSE NULL END,
				StateCode = LatestLocation.StateCode,
				AssetLocationStateId = LatestLocation.AssetLocationStateId,
				AssetLocationId = LatestLocation.AssetLocationId,
				IsIncluded = CASE WHEN LatestLocation.EffectiveFromDate > EligibleState.AssessmentDate THEN 0 ELSE 1 END
			FROM #tempTable3 Asset
			JOIN #ValidAssetLocations LatestLocation ON Asset.AssetId = LatestLocation.AssetId
			JOIN #EligibleStates EligibleState ON LatestLocation.AssetLocationStateId = EligibleState.StateId
			OUTER APPLY (SELECT TOP 1 EffectiveFromDate
						 FROM #ValidAssetLocations AssetLocationTo
						 WHERE AssetLocationTo.AssetId = Asset.AssetId
							   AND AssetLocationTo.EffectiveFromDate > LatestLocation.EffectiveFromDate
						 ORDER BY AssetLocationTo.EffectiveFromDate
						) AssetLocationTo;

			INSERT INTO #AssetLocationEffectiveDateTemp
			SELECT 
				 AssetId = Asset.AssetId,
				 EffectiveFromDate = LatestLocation.EffectiveFromDate,
				 StateCode = LatestLocation.StateCode,
				 AssetLocationStateId = LatestLocation.AssetLocationStateId ,
				 AssetLocationId = LatestLocation.AssetLocationId,
				 row_number() over(partition by Asset.AssetId order by LatestLocation.EffectiveFromDate DESC, LatestLocation.AssetLocationId DESC) RowNumber
			FROM #tempTable3 Asset
			INNER JOIN #AssetLocationEffectiveToDate LatestLocation ON Asset.AssetId = LatestLocation.AssetId AND LatestLocation.IsIncuded = 1
			INNER JOIN #EligibleStates EligibleState ON LatestLocation.AssetLocationStateId =  EligibleState.StateId
			WHERE (LatestLocation.EffectiveFromDate <= EligibleState.AssessmentDate AND LatestLocation.EffectiveToDate <= EligibleState.AssessmentDate )
			OR (LatestLocation.EffectiveFromDate <= EligibleState.AssessmentDate AND  LatestLocation.EffectiveToDate IS NULL)

			INSERT INTO #AssetLocationEffectiveDates
			SELECT AssetId,EffectiveFromDate,StateCode,AssetLocationStateId, AssetLocationId 
			FROM #AssetLocationEffectiveDateTemp WHERE RowNumber = 1 

			INSERT INTO #EligibleAssetTemp
			SELECT
				 AssetId = Asset.AssetId,    
				 IsAssetEligible = CASE
                 WHEN (LatestLocation.EffectiveFromDate BETWEEN DATEADD(YEAR,-1, EligibleState.AssessmentDate) AND EligibleState.AssessmentDate)
                 AND (LatestLocation.EffectiveToDate is null OR (LatestLocation.EffectiveToDate > EligibleState.AssessmentDate))
				 OR (LatestLocation.EffectiveFromDate < DATEADD(YEAR,-1, EligibleState.AssessmentDate) AND LatestLocation.EffectiveToDate > EligibleState.AssessmentDate)

                 THEN 1 ELSE 0 END,
				 EffectiveFromDate = LatestLocation.EffectiveFromDate ,
				 LatestLocation.StateCode,
				 LatestLocation.AssetLocationStateId ,
				 LatestLocation.AssetLocationId
			FROM #tempTable3 Asset
				INNER JOIN #AssetLocationEffectiveToDate LatestLocation ON LatestLocation.AssetId =  Asset.AssetId AND LatestLocation.IsIncuded = 1
				INNER JOIN #EligibleStates EligibleState ON LatestLocation.AssetLocationStateId = EligibleState.StateId

			INSERT INTO #EligibleAssets
			SELECT AssetId,EffectiveFromDate,StateCode,AssetLocationStateId,AssetLocationId FROM #EligibleAssetTemp WHERE IsAssetEligible = 1

			INSERT INTO #EligibleAssets
			SELECT AssetId,EffectiveFromDate,StateCode,AssetLocationStateId,AssetLocationId FROM #AssetLocationEffectiveDates WHERE AssetId NOT IN (SELECT DISTINCT AssetId FROM #EligibleAssets )

			UPDATE #tempTable3
				SET SerialNumber = ASN.SerialNumber
			FROM #tempTable3 
			JOIN (
					SELECT ASN.AssetId,
					SerialNumber = CASE WHEN count(ASN.Id) > 1 THEN 'Multiple' ELSE MAX(ASN.SerialNumber) END  
				FROM (SELECT DISTINCT AssetId FROM #tempTable3) A
				JOIN AssetSerialNumbers ASN on A.AssetId = ASN.AssetId AND ASN.IsActive=1
				GROUP BY ASN.AssetId
			)ASN ON #tempTable3.AssetId = ASN.AssetId

			INSERT INTO PropertyTaxExportJobExtracts
				(	               
					 AssetID			
					,TypeId
					,StateCode
					,AssetCategoryId
					,ManufacturerId 
					,CustomerId
					,LegalEntityId
					,Alias
					,Description
					,AcquisitionDate	
					,SerialNumber
					,ModelYear
					,IsEligibleForPropertyTax
					,PropertyTaxCost_Amount
					,PropertyTaxCost_Currency
					,AssetCatalogId
					,ProductId
					,InServiceDate 
					,AssetUsageCondition  
					,SubStatus 
					,PropertyTaxReportCode
					,FinancialType
					,AssetStatus		
					,AssetClassCode				
					,AssetLocationStateId
					,LocationEffectiveFromDate
					,LeaseFinanceDetail.LeaseContractType
					,ContractSyndicationType
					,ContractOriginationSourceType
					,PropertyTaxResponsibility 
					,IsFederalIncomeTaxExempt
					,BankQualified
					,ContractId				
					,IsContractOriginationServiced
					,IsSyndicationResponsibilityRemitOnly
					,AssetLocationId
					,DisposedDate
					,AsOfDate
					,SourceModule
					,PreviousLeaseNumber
					,TaskChunkServiceInstanceId,JobStepInstanceId    
					,CreatedById,CreatedTime,IsSubmitted
				)
			SELECT
				 Asset.AssetId
				,Asset.TypeId
				,LatestLocation.StateCode
				,Asset.AssetCategoryId
				,Asset.ManufacturerId
				,Asset.CustomerId
				,Asset.LegalEntityId
				,Asset.Alias
				,Asset.Description
				,Asset.AcquisitionDate    
				,Asset.SerialNumber
				,Asset.ModelYear
				,Asset.IsEligibleForPropertyTax
				,Asset.PropertyTaxCost_Amount
				,Asset.PropertyTaxCost_Currency
				,Asset.AssetCatalogId
				,Asset.ProductId
				,Asset.InServiceDate
				,Asset.AssetUsageCondition  
				,Asset.SubStatus
				,Asset.PropertyTaxReportCode
				,Asset.FinancialType
				,Asset.AssetStatus                    
				,Asset.AssetClassCode
				,LatestLocation.AssetLocationStateId            
				,LatestLocation.EffectiveFromDate LocationEffectiveFromDate
				,LeaseContractType
				,ContractSyndicationType
				,ContractOriginationSourceType
				,AssetDetails.PropertyTaxResponsibility 
				,IsFederalIncomeTaxExempt
				,BankQualified
				,ContractId			
				,IsContractOriginationServiced
				,IsSyndicationResponsibilityRemitOnly
				,LatestLocation.AssetLocationId
				,Asset.DisposedDate
				,Asset.AsOfDate
				,Asset.SourceModule
				,Asset.PreviousLeaseNumber
				,@TaskChunkServiceInstanceId,@JobStepInstanceId
				,@CreatedById,@CreatedTime,0            
			FROM #tempTable3 Asset
				INNER JOIN #EligibleAssets LatestLocation ON LatestLocation.AssetId =  Asset.AssetId
				LEFT JOIN #tempTable2 AssetDetails ON Asset.AssetId =  AssetDetails.AssetId
			ORDER BY Asset.AssetId

			SET @start = @End + 1

			TRUNCATE TABLE #ValidAssetLocations
			TRUNCATE TABLE #HistoricalAssetData
			TRUNCATE TABLE #tempTable2
			TRUNCATE TABLE #tempTable3
			TRUNCATE TABLE #AsOfDateAssetHistoryData
			TRUNCATE TABLE #AssetLocationEffectiveDateTemp
			TRUNCATE TABLE #AssetLocationEffectiveDates
			TRUNCATE TABLE #AssetLocationEffectiveToDate
			TRUNCATE TABLE #EligibleAssetTemp
			TRUNCATE TABLE #EligibleAssets

		END -- End of Chunking

		DELETE from PropertyTaxCombinedTaxRates -- This is for PTMS Details TaxRate need to be empty before it is used
				
		IF OBJECT_ID('tempDB..#ValidAssetLocations') IS NOT NULL
			DROP TABLE #ValidAssetLocations
		IF OBJECT_ID('tempDB..#HistoricalAssetData') IS NOT NULL
			DROP TABLE #HistoricalAssetData			
		IF OBJECT_ID('tempDB..#tempTable2') IS NOT NULL
			DROP TABLE #tempTable2	
		IF OBJECT_ID('tempDB..#tempTable3') IS NOT NULL
			DROP TABLE #tempTable3	
		IF OBJECT_ID('tempDB..#AsOfDateAssetHistoryData') IS NOT NULL
			DROP TABLE #AsOfDateAssetHistoryData
		IF OBJECT_ID('tempDB..#AssetLocationEffectiveDateTemp') IS NOT NULL
			DROP TABLE #AssetLocationEffectiveDateTemp
		IF OBJECT_ID('tempDB..#AssetLocationEffectiveDates') IS NOT NULL
			DROP TABLE #AssetLocationEffectiveDates
		IF OBJECT_ID('tempDB..#AssetLocationEffectiveToDate') IS NOT NULL
			DROP TABLE #AssetLocationEffectiveToDate
		IF OBJECT_ID('tempDB..#EligibleAssetTemp') IS NOT NULL
			DROP TABLE #EligibleAssetTemp
		IF OBJECT_ID('tempDB..#EligibleAssets') IS NOT NULL
			DROP TABLE #EligibleAssets
			
	SET NOCOUNT OFF  
	SET ANSI_WARNINGS ON 				
	END

GO
