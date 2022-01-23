SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[InsertSalesTaxReversalReceivableDetails]	
(
	@ReceivableIds ReceivableIdCollection null Readonly,
	@ReceivableDetailIds ReceivableDetailIdCollection null Readonly ,	
	@InvoicedBilledStatusValue NVARCHAR(20),	
	@BuyOut NVARCHAR(20),	
	@AssetSale NVARCHAR(20),	
	@InvoicedOrCashPosted NVARCHAR(40),	
	@LEWithoutGLPeriod NVARCHAR(40),	
	@LEWithInvalidGLPeriod NVARCHAR(40),	
	@PostDate DATETIMEOFFSET,	
	@CTEntityType NVARCHAR(20),	
	@SALE NVARCHAR(20),	
	@LEASE NVARCHAR(20),	
	@TotalProcessingCount BIGINT = 0 OUTPUT,	
	@JobStepInstanceId BIGINT,	
	@ReceivableWithApprovedTP NVARCHAR(40),
	@IsFromVATReassessment BIT
)	
AS	
BEGIN	

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE

CREATE TABLE #ReceivableDetails(ReceivableDetailId BIGINT)

INSERT INTO #ReceivableDetails  
SELECT DISTINCT ReceivableDetailId FROM
	(SELECT ReceivableDetailId FROM @ReceivableDetailIds
	UNION ALL
	SELECT 
		Id 
	FROM ReceivableDetails RD 
	JOIN @ReceivableIds R On RD.ReceivableId = R.ReceivableId
	)T

INSERT INTO ReversalReceivableDetail_Extract (ReceivableTaxId, IsCashPosted,ReceivableTaxDetailId, ReceivableDetailId, Currency,TaxAreaId, Cost,	
	ExtendedPrice, FairMarketValue, TaxBasisType, AssetId, AssetType, LocationId, DueDate, ReceivableId, ReceivableCodeId, IsInvoiced, 	
	IsExemptAtLease, IsExemptAtAsset, IsExemptAtSundry, Company, Product, ContractType, LeaseType, LeaseTerm, TitleTransferCode, 	
	TransactionCode, AmountBilledToDate, AssetLocationId, ToState, FromState, SundryReceivableCode, IsExemptAtReceivableCode, 	
	TransactionType, ReceivableType, IsRental, CustomerId, ContractId, LegalEntityId, EntityType, IsVertexSupported, ReceivableDetailRowVersion,	
	ReceivableTaxRowVersion, ReceivableTaxDetailRowVersion, AssetLocationRowVersion, CreatedById, CreatedTime,JobStepInstanceId,UpfrontTaxSundryId,
	SalesTaxRemittanceResponsibility,IsAssessSalesTaxAtSKULevel, UpfrontTaxAssessedInLegacySystem,ErrorCode,ReceivableTaxType)	
SELECT 	RT.Id AS ReceivableTaxId
	,CASE WHEN (RT.Balance_Amount != RT.Amount_Amount) THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END IsCashPosted 	
	,RTD.Id As ReceivableTaxDetailId	
	,RTD.ReceivableDetailId AS ReceivableDetailId	
	,RTD.Revenue_Currency AS Currency	
	,RTD.TaxAreaId AS TaxAreaId	
	,RTD.Cost_Amount*(-1) AS Cost	
	,RTD.Revenue_Amount*(-1) AS ExtendedPrice	
	,RTD.FairMarketValue_Amount*(-1) AS FairMarketValue	
	,RTD.TaxBasisType AS TaxBasisType	
	,RTD.AssetId 	
	,RTRD.AssetType
	,RTD.LocationId	
	,R.DueDate AS DueDate	
	,R.Id AS ReceivableId	
	,R.ReceivableCodeId	
	,CASE WHEN RD.BilledStatus = @InvoicedBilledStatusValue THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END IsInvoiced	
	,ISNULL(RTRD.IsExemptAtLease,CONVERT(BIT,0)) AS IsExemptAtLease	
	,ISNULL(RTRD.IsExemptAtAsset,CONVERT(BIT,0)) AS IsExemptAtAsset	
	,ISNULL(RTRD.IsExemptAtSundry,CONVERT(BIT,0)) AS IsExemptAtSundry	
	,RTRD.Company	
	,RTRD.Product	
	,RTRD.ContractType	
	,RTRD.LeaseType	
	,RTRD.LeaseTerm	
	,RTRD.TitleTransferCode	
	,RTRD.TransactionCode	
	,ISNULL(RTRD.AmountBilledToDate,0) AS AmountBilledToDate	
	,RTRD.AssetLocationId	
	,RTRD.ToStateName ToState	
	,RTRD.FromStateName FromState	
	,RC.Name AS SundryReceivableCode	
	,RC.IsTaxExempt IsExemptAtReceivableCode	
	,CASE WHEN (RecType.Name = @BuyOut OR RecType.Name = @AssetSale) THEN @SALE ELSE @LEASE END AS TransactionType	
	,RecType.Name ReceivableType	
	,RecType.IsRental AS IsRental	
	,R.CustomerId	
	,CASE WHEN R.EntityType = @CTEntityType THEN R.EntityId ELSE NULL END AS ContractId	
	,LE.Id AS LegalEntityId
	,R.EntityType	
	,CAST(0 AS Bit) IsVertexSupported	
	,RD.RowVersion	
	,RT.RowVersion	
	,RTD.RowVersion	
	,AL.RowVersion	
	,CreatedById = 1	
	,CreatedTime = SYSDATETIMEOFFSET()	
	,@JobStepInstanceId	
	,RTD.UpfrontTaxSundryId	
	,ISNULL(RTRD.SalesTaxRemittanceResponsibility,'_') AS SalesTaxRemittanceResponsibility
	,LE.IsAssessSalesTaxAtSKULevel
	,ISNULL(RTRD.UpfrontTaxAssessedInLegacySystem, CAST(0 AS BIT))
	,CASE WHEN (@IsFromVATReassessment = 0 AND ((CASE WHEN RD.BilledStatus = @InvoicedBilledStatusValue THEN CAST(1 AS BIT) 
														ELSE CAST(0 AS BIT) END) = 1 
											OR (CASE WHEN (RT.Balance_Amount != RT.Amount_Amount) THEN CAST(1 AS BIT) 
														ELSE CAST(0 AS BIT) END) = 1))
		  THEN @InvoicedOrCashPosted ELSE NULL END ErrorCode
	,R.ReceivableTaxType AS ReceivableTaxType
FROM #ReceivableDetails TRD
INNER JOIN ReceivableDetails RD ON TRD.ReceivableDetailId = RD.Id
INNER JOIN Receivables R ON RD.ReceivableId = R.Id
INNER JOIN LegalEntities LE ON R.LegalEntityId = LE.Id
INNER JOIN ReceivableTaxDetails RTD ON RD.Id = RTD.ReceivableDetailId	
INNER JOIN ReceivableTaxes RT ON RTD.ReceivableTaxId = RT.Id
INNER JOIN ReceivableCodes RC ON R.ReceivableCodeId = RC.Id	
INNER JOIN ReceivableTypes RecType ON RC.ReceivableTypeId = RecType.Id
LEFT JOIN ReceivableTaxReversalDetails RTRD ON RTD.Id = RTRD.Id --Left Join since ReceivableTaxReversalDetails will not have any values for NonVertex and here we are taking details for both vertex and non-vertex	
LEFT JOIN AssetLocations AL ON RTRD.AssetLocationId = AL.Id	
WHERE R.IsActive = 1 AND RD.IsActive = 1 AND RTD.IsActive = 1	
AND RD.IsTaxAssessed = 1;


WITH CTE_DistinctLegalEntities AS	
(	
	Select DISTINCT LegalEntityId FROM ReversalReceivableDetail_Extract R 
	WHERE	R.JobStepInstanceId = @JobStepInstanceId AND R.IsInvoiced = 0 AND R.IsCashPosted = 0  	
)	
SELECT  R.LegalEntityId,		
	FromDate,	
	ToDate,	
	LE.Name AS LegalEntityName,	
	CASE WHEN GLF.Id IS NOT NULL	
	THEN CAST(1 AS BIT)	
	ELSE CAST(0 AS BIT)	
	END HasGLPeriod,	
	CASE WHEN GLF.Id IS NOT NULL	
	THEN CASE WHEN @PostDate >= FromDate AND @PostDate <= ToDate	
	THEN CAST(1 AS BIT)	
	ELSE CAST(0 AS BIT)	
	END	
	ELSE CAST(0 AS BIT) END IsPostDateValid	
INTO #LegalEntitiesInfo	
FROM CTE_DistinctLegalEntities R	
INNER JOIN LegalEntities LE ON R.LegalEntityId = LE.Id	
LEFT JOIN GLFinancialOpenPeriods GLF ON R.LegalEntityId = GLF.LegalEntityId AND GLF.IsCurrent = 1	

UPDATE R	
SET ErrorCode = @LEWithoutGLPeriod,	
LegalEntityName = L.LegalEntityName	
FROM ReversalReceivableDetail_Extract R	
INNER JOIN #LegalEntitiesInfo L ON R.LegalEntityId = L.LegalEntityId	
WHERE R.JobStepInstanceId = @JobStepInstanceId AND L.HasGLPeriod = 0 	

UPDATE R	
SET ErrorCode = @LEWithInvalidGLPeriod,	
LegalEntityName = L.LegalEntityName,	
GLFinancialOpenPeriodFromDate = FromDate,	
GLFinancialOpenPeriodToDate = ToDate	
FROM ReversalReceivableDetail_Extract R	
INNER JOIN #LegalEntitiesInfo L ON R.LegalEntityId = L.LegalEntityId	
WHERE R.JobStepInstanceId = @JobStepInstanceId AND HasGLPeriod = 1 AND IsPostDateValid = 0  

SELECT 
	PV.VoucherNumber,	
	R.Id 
INTO #PaymentVoucherDetails	
FROM ReversalReceivableDetail_Extract R	
INNER JOIN ReceivableTaxDetails RTD ON R.ReceivableTaxDetailId = RTD.Id	
INNER JOIN Sundries S ON S.Id = RTD.UpfrontTaxSundryId  AND S.IsActive=1	
INNER JOIN Payables P ON P.Id = S.PayableId	
INNER JOIN TreasuryPayableDetails TPD ON TPD.PayableId = P.Id	
INNER JOIN TreasuryPayables TP ON TP.Id = TPD.TreasuryPayableId	
INNER JOIN PaymentVoucherDetails PVD ON PVD.TreasuryPayableId = TP.ID	
INNER JOIN PaymentVouchers PV ON PV.Id = PVD.PaymentVoucherId	
WHERE R.JobStepInstanceId = @JobStepInstanceId
AND PV.Status <>'InActive'	
AND TP.Status='Approved'	
AND P.Status <>'Inactive'	
AND S.IsActive = 1	
AND RTD.IsActive = 1	
AND PV.Status <>'Reversed'	

UPDATE R SET ErrorCode = @ReceivableWithApprovedTP, VoucherNumbers = T.VoucherNumbers	
FROM ReversalReceivableDetail_Extract R	
INNER JOIN (
	SELECT PVD.ID ,	
		SUBSTRING(STUFF((SELECT  ',' + VoucherNumber	
	FROM #PaymentVoucherDetails InnerPVD	
	WHERE InnerPVD.ID = PVD.ID	
	FOR XML PATH(''), TYPE).value('.[1]', 'NVARCHAR(MAX)'), 1, 1, ''),1,100000) AS VoucherNumbers	
	FROM #PaymentVoucherDetails PVD	
	GROUP BY PVD.Id) T ON T.Id = R.Id	
WHERE R.JobStepInstanceId = @JobStepInstanceId	

UPDATE RD SET	
RD.AcquisitionLocationId = LA.AcquisitionLocationId	
FROM ReversalReceivableDetail_Extract RD	
INNER JOIN LeaseFinances LF ON RD.ContractId = LF.ContractID AND LF.IsCurrent = 1	
INNER JOIN LeaseAssets LA ON LA.LeaseFinanceId = LF.Id AND LA.AssetId = RD.AssetId 
AND (LA.IsActive = 1 OR (LA.IsActive = 0 AND LA.TerminationDate IS NOT NULL))	
WHERE RD.JobStepInstanceId = @JobStepInstanceId	

SELECT @TotalProcessingCount = COUNT(distinct ReceivableId)	
FROM ReversalReceivableDetail_Extract	
WHERE JobStepInstanceId = @JobStepInstanceId

DROP TABLE #PaymentVoucherDetails
DROP TABLE #LegalEntitiesInfo
DROP TABLE #ReceivableDetails

END

GO
