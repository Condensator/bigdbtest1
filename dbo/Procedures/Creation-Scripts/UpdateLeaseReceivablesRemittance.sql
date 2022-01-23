SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[UpdateLeaseReceivablesRemittance]
(
@EntityType NVARCHAR(50),
@EntityId BIGINT,
@FromDate DATETIME,
@ToDate DATETIME,
@IsPrivateLabel BIT,
@IsServicedDeal BIT,
@IsCollectedDeal BIT,
@IsDealLevelBillTo BIT,
@CreatedById BIGINT,
@CreatedTime DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON

SELECT 
	Id
INTO #ValidReceivableTypes 
FROM ReceivableTypes
WHERE IsActive = 1
AND Name IN ('CapitalLeaseRental','OperatingLeaseRental','LeaseFloatRateAdj','LeaseInterimInterest','InterimRental','OverTermRental','Supplemental')

SELECT 
	Receivables.Id, 
	Receivables.PaymentScheduleId, 
	Receivables.EntityId, 
	Receivables.ReceivableCodeId, 
	Receivables.SourceTable, 
	Receivables.DueDate
INTO #AllReceivables
FROM Receivables
WHERE Receivables.EntityType = @EntityType
AND Receivables.EntityId = @EntityId
AND Receivables.IsActive = 1

If(Select DiscountingSharedPercentage from Contracts where Id=@EntityId)>0
BEGIN
SELECT
DiscountingFinances.DiscountingId,
DiscountingServicingDetails.Collected,
DiscountingServicingDetails.PerfectPay,
DiscountingServicingDetails.EffectiveDate,
ROW_NUMBER() OVER (PARTITION BY DiscountingFinances.DiscountingId ORDER BY DiscountingServicingDetails.EffectiveDate) RowNumber
INTO #ServicingDetails
FROM Contracts
JOIN DiscountingContracts  ON Contracts.Id=DiscountingContracts.ContractId
JOIN DiscountingFinances  ON DiscountingContracts.DiscountingFinanceId=DiscountingFinances.Id AND  DiscountingFinances.ApprovalStatus='Approved'
JOIN DiscountingServicingDetails ON DiscountingFinances.Id = DiscountingServicingDetails.DiscountingFinanceId AND DiscountingServicingDetails.IsActive=1
where Contracts.Id=@EntityId
SELECT DISTINCT Receivables.Id
INTO #Receivables
FROM
CONTRACTS
JOIN TiedContractPaymentDetails ON Contracts.Id=TiedContractPaymentDetails.ContractId
JOIN Receivables ON TiedContractPaymentDetails.PaymentScheduleId=Receivables.PaymentScheduleId
JOIN LeasePaymentSchedules ON Receivables.PaymentScheduleId = LeasePaymentSchedules.Id
WHERE  Contracts.Id=@EntityId
AND LeasePaymentSchedules.StartDate >= @FromDate AND LeasePaymentSchedules.StartDate < @ToDate
UPDATE Receivables
SET
RemitToId = CASE WHEN DiscountingServicingDetails.Collected =0 THEN Receivables.RemitToId ELSE Contracts.RemitToId END,
TaxRemitToId = CASE WHEN DiscountingServicingDetails.Collected =0 THEN Receivables.RemitToId ELSE Contracts.RemitToId END,
IsPrivateLabel = CASE WHEN DiscountingServicingDetails.Collected IS NULL THEN @IsPrivateLabel ELSE Receivables.IsPrivateLabel END,
IsServiced = CASE WHEN DiscountingServicingDetails.Collected IS NULL THEN @IsServicedDeal ELSE Receivables.IsServiced END,
IsCollected = CASE WHEN DiscountingServicingDetails.Collected IS NULL THEN @IsCollectedDeal ELSE Receivables.IsCollected END,
UpdatedById = @CreatedById,
UpdatedTime = @CreatedTime
FROM Contracts
JOIN DiscountingContracts  ON Contracts.Id=DiscountingContracts.ContractId
JOIN DiscountingFinances  ON DiscountingContracts.DiscountingFinanceId=DiscountingFinances.Id AND
DiscountingFinances.ApprovalStatus='Approved'
JOIN DiscountingServicingDetails ON DiscountingFinances.Id= DiscountingServicingDetails.DiscountingFinanceId
AND  DiscountingServicingDetails.IsActive=1
JOIN DiscountingRepaymentSchedules ON DiscountingFinances.Id = DiscountingRepaymentSchedules.DiscountingFinanceId AND
DiscountingRepaymentSchedules.IsActive=1
JOIN #ServicingDetails ServicingDetail ON DiscountingFinances.DiscountingId = ServicingDetail.DiscountingId
LEFT JOIN #ServicingDetails NextServicingDetail ON ServicingDetail.DiscountingId = NextServicingDetail.DiscountingId AND
ServicingDetail.RowNumber + 1 = NextServicingDetail.RowNumber
JOIN TiedContractPaymentDetails ON DiscountingRepaymentSchedules.Id= TiedContractPaymentDetails.DiscountingRepaymentScheduleId
JOIN Receivables ON TiedContractPaymentDetails.PaymentScheduleId=Receivables.PaymentScheduleId
JOIN ReceivableCodes ON Receivables.ReceivableCodeId = ReceivableCodes.Id
JOIN ReceivableDetails ON Receivables.Id = ReceivableDetails.ReceivableId
JOIN #Receivables ON Receivables.Id=#Receivables.Id
JOIN #ValidReceivableTypes ReceivableTypes ON ReceivableCodes.ReceivableTypeId = ReceivableTypes.Id
JOIN LeasePaymentSchedules ON Receivables.PaymentScheduleId = LeasePaymentSchedules.Id
WHERE
Receivables.IsActive = 1
AND LeasePaymentSchedules.StartDate >= @FromDate AND LeasePaymentSchedules.StartDate < @ToDate
AND Receivables.EntityType=@EntityType
AND Receivables.EntityId=@EntityId
AND ReceivableDetails.BilledStatus <> 'Invoiced'
UPDATE Receivables
SET
RemitToId = Contracts.RemitToId,
TaxRemitToId = Contracts.RemitToId,
IsPrivateLabel = @IsPrivateLabel,
IsServiced = @IsServicedDeal,
IsCollected = @IsCollectedDeal,
UpdatedById = @CreatedById,
UpdatedTime = @CreatedTime
FROM
Receivables
JOIN LeasePaymentSchedules ON Receivables.PaymentScheduleId = LeasePaymentSchedules.Id
JOIN Contracts ON Receivables.EntityId = Contracts.Id
JOIN ReceivableCodes ON Receivables.ReceivableCodeId = ReceivableCodes.Id
JOIN #ValidReceivableTypes ReceivableTypes ON ReceivableCodes.ReceivableTypeId = ReceivableTypes.Id
JOIN ReceivableDetails ON Receivables.Id = ReceivableDetails.ReceivableId
WHERE
Receivables.IsActive = 1
AND LeasePaymentSchedules.StartDate >= @FromDate AND LeasePaymentSchedules.StartDate < @ToDate
AND Receivables.EntityType=@EntityType
AND Receivables.EntityId=@EntityId
AND ReceivableDetails.BilledStatus <> 'Invoiced'
AND Receivables.Id NOT IN (Select Id from #Receivables)
END
ELSE
BEGIN
UPDATE Rec
SET
RemitToId = Contracts.RemitToId,
TaxRemitToId = Contracts.RemitToId,
IsPrivateLabel = @IsPrivateLabel,
IsServiced = @IsServicedDeal,
IsCollected = @IsCollectedDeal,
UpdatedById = @CreatedById,
UpdatedTime = @CreatedTime
FROM
Receivables Rec
JOIN #AllReceivables Receivables ON Rec.Id = Receivables.Id
JOIN LeasePaymentSchedules ON Receivables.PaymentScheduleId = LeasePaymentSchedules.Id
JOIN Contracts ON Receivables.EntityId = Contracts.Id
JOIN ReceivableCodes ON Receivables.ReceivableCodeId = ReceivableCodes.Id
JOIN #ValidReceivableTypes ReceivableTypes ON ReceivableCodes.ReceivableTypeId = ReceivableTypes.Id
JOIN ReceivableDetails ON Receivables.Id = ReceivableDetails.ReceivableId
LEFT JOIN ReceivableForTransfers ON ReceivableForTransfers.ContractId=Contracts.Id
WHERE
LeasePaymentSchedules.StartDate >= @FromDate AND LeasePaymentSchedules.StartDate < @ToDate
AND (Contracts.SyndicationType='None' OR LeasePaymentSchedules.StartDate < ReceivableForTransfers.EffectiveDate)
AND ReceivableDetails.BilledStatus <> 'Invoiced'
END

UPDATE ReceivableDetails
SET
BillToId = CASE WHEN @IsDealLevelBillTo = 0 THEN LeaseAssets.BillToId ELSE Contracts.BillToId END,
UpdatedById = @CreatedById,
UpdatedTime = @CreatedTime
FROM
ReceivableDetails
JOIN #AllReceivables Receivables ON ReceivableDetails.ReceivableId = Receivables.Id
JOIN LeasePaymentSchedules ON Receivables.PaymentScheduleId = LeasePaymentSchedules.Id
JOIN LeaseAssets ON ReceivableDetails.AssetId = LeaseAssets.AssetId
JOIN LeaseFinances ON LeaseAssets.LeaseFinanceId = LeaseFinances.Id
JOIN Contracts ON LeaseFinances.ContractId = Contracts.Id
WHERE
LeaseAssets.IsActive = 1
AND LeaseFinances.IsCurrent = 1
AND LeasePaymentSchedules.StartDate >= @FromDate AND LeasePaymentSchedules.StartDate < @ToDate
AND SourceTable != 'CPUSchedule'
AND ReceivableDetails.BilledStatus <> 'Invoiced'
AND ReceivableDetails.IsActive = 1

UPDATE Rec
SET
RemitToId = Contracts.RemitToId,
TaxRemitToId = Contracts.RemitToId,
IsPrivateLabel = @IsPrivateLabel,
IsServiced = @IsServicedDeal,
IsCollected = @IsCollectedDeal,
UpdatedById = @CreatedById,
UpdatedTime = @CreatedTime
FROM
Receivables Rec
JOIN #AllReceivables Receivables ON Rec.Id = Receivables.Id
JOIN ReceivableDetails ON Receivables.Id = ReceivableDetails.ReceivableId
JOIN Sundries ON Receivables.Id = Sundries.ReceivableId
JOIN BlendedItemDetails ON Sundries.Id = BlendedItemDetails.SundryId
JOIN LeaseBlendedItems ON BlendedItemDetails.BlendedItemId = LeaseBlendedItems.BlendedItemId
JOIN LeaseFinances ON LeaseBlendedItems.LeaseFinanceId = LeaseFinances.Id AND LeaseFinances.IsCurrent=1
JOIN Contracts ON Receivables.EntityId = Contracts.Id AND LeaseFinances.ContractId = Contracts.Id
LEFT JOIN ReceivableForTransfers ON ReceivableForTransfers.ContractId = Contracts.Id
WHERE
Receivables.DueDate >= @FromDate AND Receivables.DueDate < @ToDate
AND (Contracts.SyndicationType='None' OR Receivables.DueDate <= ReceivableForTransfers.EffectiveDate)
AND ReceivableDetails.BilledStatus <> 'Invoiced'
AND ReceivableDetails.IsActive = 1

DROP TABLE #ValidReceivableTypes
DROP TABLE #AllReceivables
IF OBJECT_ID('tempdb..#Receivables') IS NOT NULL
DROP TABLE #Receivables
IF OBJECT_ID('tempdb..#ServicingDetails') IS NOT NULL
DROP TABLE #ServicingDetails
END

GO
