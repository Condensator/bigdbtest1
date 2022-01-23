SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[InsertSalesTaxReversalContractBasedReceivableDetails]
(
@ContractId BIGINT = NULL,
@LegalEntityIds LegalEntityIdCollection Readonly,
@FromDate DATETIMEOFFSET,
@ToDate DATETIMEOFFSET = NULL,
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
@ReceivableWithApprovedTP NVARCHAR(40)
)
AS
BEGIN
INSERT INTO ReversalReceivableDetail_Extract (ReceivableTaxId, IsCashPosted,ReceivableTaxDetailId, ReceivableDetailId, Currency,TaxAreaId, Cost,
		ExtendedPrice, FairMarketValue, TaxBasisType, AssetId, AssetType, LocationId, DueDate, ReceivableId, ReceivableCodeId, IsInvoiced, 
		IsExemptAtLease, IsExemptAtAsset, IsExemptAtSundry, Company, Product, ContractType, LeaseType, LeaseTerm, TitleTransferCode, 
		TransactionCode, AmountBilledToDate, AssetLocationId, ToState, FromState, SundryReceivableCode, IsExemptAtReceivableCode, 
		TransactionType, ReceivableType, IsRental, CustomerId, ContractId, LegalEntityId, EntityType, IsVertexSupported, ReceivableDetailRowVersion,
		ReceivableTaxRowVersion, ReceivableTaxDetailRowVersion, AssetLocationRowVersion, CreatedById, CreatedTime, JobStepInstanceId,UpfrontTaxSundryId,
		SalesTaxRemittanceResponsibility, IsAssessSalesTaxAtSKULevel, UpfrontTaxAssessedInLegacySystem, ReceivableTaxType, PaymentScheduleId, BusCode)
SELECT  RT.Id AS ReceivableTaxId
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
		,LE.LegalEntityId AS LegalEntityId
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
		,L.IsAssessSalesTaxAtSKULevel
		,ISNULL(RTRD.UpfrontTaxAssessedInLegacySystem, CAST(0 AS BIT))
		,R.ReceivableTaxType AS ReceivableTaxType
		,R.PaymentScheduleId
		,RTRD.BusCode
FROM ReceivableTaxes RT
INNER JOIN ReceivableTaxDetails RTD ON RT.Id = RTD.ReceivableTaxId
INNER JOIN Receivables R ON RT.ReceivableId = R.Id
INNER JOIN ReceivableDetails RD ON RTD.ReceivableDetailId = RD.Id
INNER JOIN ReceivableCodes RC ON R.ReceivableCodeId = RC.Id
INNER JOIN ReceivableTypes RecType ON RC.ReceivableTypeId = RecType.Id
INNER JOIN LegalEntities L ON R.LegalEntityId = L.Id
INNER JOIN @LegalEntityIds LE ON L.Id = LE.LegalEntityId
LEFT JOIN ReceivableTaxReversalDetails RTRD ON RTD.Id = RTRD.Id --Left Join since ReceivableTaxReversalDetails will not have any values for NonVertex and here we are taking details for both vertex and non-vertex
LEFT JOIN AssetLocations AL ON RTRD.AssetLocationId = AL.Id
WHERE R.DueDate >= @FromDate
AND (@ToDate IS NULL OR R.DueDate <= @ToDate)
AND R.IsActive = 1 AND RD.IsActive = 1 AND RTD.IsActive = 1
AND RD.IsTaxAssessed = 1
AND R.EntityId = @ContractId
AND R.EntityType = @CTEntityType
UPDATE ReversalReceivableDetail_Extract
SET ErrorCode = @InvoicedOrCashPosted
WHERE (IsInvoiced = 1 OR IsCashPosted = 1) AND JobStepInstanceId = @JobStepInstanceId;
WITH CTE_DistinctLegalEntities AS
(
Select DISTINCT LegalEntityId FROM ReversalReceivableDetail_Extract R
WHERE R.IsInvoiced = 0 AND R.IsCashPosted = 0 AND R.JobStepInstanceId = @JobStepInstanceId
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
WHERE L.HasGLPeriod = 0 AND R.JobStepInstanceId = @JobStepInstanceId
UPDATE R
SET ErrorCode = @LEWithInvalidGLPeriod,
LegalEntityName = L.LegalEntityName,
GLFinancialOpenPeriodFromDate = FromDate,
GLFinancialOpenPeriodToDate = ToDate
FROM ReversalReceivableDetail_Extract R
INNER JOIN #LegalEntitiesInfo L ON R.LegalEntityId = L.LegalEntityId
WHERE HasGLPeriod = 1 AND IsPostDateValid = 0 AND R.JobStepInstanceId = @JobStepInstanceId
SELECT PV.VoucherNumber,
R.Id INTO #PaymentVoucherDetails
FROM ReversalReceivableDetail_Extract R
INNER JOIN ReceivableTaxDetails RTD ON R.ReceivableTaxDetailId = RTD.Id
INNER JOIN Sundries S ON S.Id = RTD.UpfrontTaxSundryId  AND S.IsActive=1
INNER JOIN Payables P ON P.Id = S.PayableId
INNER JOIN TreasuryPayableDetails TPD ON TPD.PayableId = P.Id
INNER JOIN TreasuryPayables TP ON TP.Id = TPD.TreasuryPayableId
INNER JOIN PaymentVoucherDetails PVD ON PVD.TreasuryPayableId = TP.ID
INNER JOIN PaymentVouchers PV ON PV.Id = PVD.PaymentVoucherId
WHERE PV.Status <>'InActive'
AND TP.Status='Approved'
AND P.Status <>'Inactive'
AND S.IsActive = 1
AND RTD.IsActive = 1
AND PV.Status <>'Reversed'
AND R.JobStepInstanceId = @JobStepInstanceId
UPDATE R SET ErrorCode = @ReceivableWithApprovedTP, VoucherNumbers = T.VoucherNumbers
FROM ReversalReceivableDetail_Extract R
INNER JOIN (SELECT PVD.ID ,
SUBSTRING(STUFF((SELECT  ',' + VoucherNumber
FROM #PaymentVoucherDetails InnerPVD
WHERE InnerPVD.ID = PVD.ID
FOR XML PATH(''), TYPE)
.value('.[1]', 'nvarchar(max)'), 1, 1, ''),1,100000) AS VoucherNumbers
FROM #PaymentVoucherDetails PVD
GROUP BY PVD.Id) T ON T.Id = R.Id
WHERE  R.JobStepInstanceId = @JobStepInstanceId
UPDATE RD SET
RD.AcquisitionLocationId = LA.AcquisitionLocationId
FROM ReversalReceivableDetail_Extract RD
INNER JOIN Contracts Co ON Co.Id = RD.ContractId
INNER JOIN LeaseFinances LF ON Co.Id = LF.ContractID AND LF.IsCurrent = 1
INNER JOIN LeaseAssets LA ON LA.LeaseFinanceId = LF.Id AND LA.AssetId = RD.AssetId AND (LA.IsActive = 1 OR (LA.IsActive = 0 AND LA.TerminationDate IS NOT NULL))
WHERE RD.JobStepInstanceId = @JobStepInstanceId
SELECT @TotalProcessingCount = COUNT(distinct ReceivableId)
FROM ReversalReceivableDetail_Extract
WHERE JobStepInstanceId = @JobStepInstanceId
END

GO
