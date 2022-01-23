SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[GetVATReceivableInfo]
(
 @LeaseFinanceId BIGINT ,
 @LeasePaymentScheduleSourceType NVARCHAR(20),
 @AdditionalChargeSourceType NVARCHAR(16),
 @BlendedItemSourceType  NVARCHAR(11),
 @SecurityDepositSourceType  NVARCHAR(15),
 @SundryRecurringSourceType  NVARCHAR(15),
 @SundrySourceType  NVARCHAR(6),
 @PayOffSourceType  NVARCHAR(6),
 @ContractCurrency NVARCHAR(3),
 @EffectiveDate DATE = NULL
)
AS
BEGIN
DECLARE @ContractId BIGINT = (SELECT ContractId FROM LeaseFinances WHERE id = @LeaseFinanceId)
DECLARE @IsAdvance BIT = (SELECT IsAdvance FROM LeaseFinanceDetails WHERE Id = @LeaseFinanceId)
DECLARE @IsRestructureAtInception BIT = (SELECT AmendmentAtInception FROM LeaseAmendments 
											WHERE CurrentLeaseFinanceId = @LeaseFinanceId AND AmendmentType IN('Rebook','Restructure'))
DECLARE @ReceivableEntityType NVARCHAR(2)='CT'
DECLARE @OverTermPaymentType NVARCHAR(28)='OTP'
DECLARE @SupplementPaymentType NVARCHAR(28)='Supplemental'
DECLARE @InterimRentPaymentType NVARCHAR(28)='InterimRent'
DECLARE @InterimInterestPaymentType NVARCHAR(28)='InterimInterest'
DECLARE @PreviousLeaseFinanceId BIGINT = (SELECT OriginalLeaseFinanceId FROM LeaseAmendments 
									       WHERE CurrentLeaseFinanceId = @LeaseFinanceId  AND AmendmentType IN('Rebook','Restructure')) 


SET @EffectiveDate = CASE WHEN (@IsAdvance = 1 OR @IsRestructureAtInception = 1) THEN DATEADD(dd,-1,@EffectiveDate) ELSE @EffectiveDate END

IF OBJECT_ID('tempDB..#VATReceivableInfo') IS NOT NULL
DROP TABLE #VATReceivableInfo
IF OBJECT_ID('tempDB..#BlendedItemVATReceivableInfoOnRestructure') IS NOT NULL
DROP TABLE #BlendedItemVATReceivableInfoOnRestructure
IF OBJECT_ID('tempDB..#PayOffSundriesVATInfo') IS NOT NULL
DROP TABLE #PayOffSundriesVATInfo
IF OBJECT_ID('tempDB..#PayOffSundriesVATInfo') IS NOT NULL
DROP TABLE #PayOffSundriesVATInfo
IF OBJECT_ID('tempDB..#OriginalAndAdjustedReceivables') IS NOT NULL
DROP TABLE #OriginalAndAdjustedReceivables
IF OBJECT_ID('tempDB..#InContractSundryDetails') IS NOT NULL
DROP TABLE #InContractSundryDetails

CREATE TABLE #VATReceivableInfo
(
LeaseFinanceId BIGINT,
SourceId BIGINT,
SourceType NVARCHAR(20),
ReceivableId BIGINT,
DueDate DATE,
ReceivableAmount_Amount NUMERIC(16,2),
ProjectedVATAmount_Amount NUMERIC(16,2),
ActualVATAmount_Amount NUMERIC(16,2),
TotalAmount_Amount NUMERIC(16,2),
TotalBalance_Amount NUMERIC(16,2),
IsTaxAssessed BIT,
IsAdjustmentReceivable BIT,
ReceivableType NVARCHAR(21),
PaymentType NVARCHAR(28),
ParentBlendedItemId BIGINT,
IsAdditionalChargeNewlyAdded BIT,
AdditionalChargeProcessedThroughDate DATE
)

--FIXED TERM RENTALS AND OTP/SUPPLEMENTAL
INSERT INTO #VATReceivableInfo
(
LeaseFinanceId
,SourceId
,SourceType
,ReceivableId
,DueDate
,ReceivableAmount_Amount
,ProjectedVATAmount_Amount
,ActualVATAmount_Amount
,TotalBalance_Amount
,IsTaxAssessed
,ReceivableType
,PaymentType
)
SELECT
LeasePaymentSchedules.LeaseFinanceDetailId
,ISNULL(Receivables.PaymentScheduleId,LeasePaymentSchedules.Id) AS [SourceId]
,@LeasePaymentScheduleSourceType AS [SourceType]
,Receivables.Id AS [ReceivableId]
,ISNULL(Receivables.DueDate,LeasePaymentSchedules.DueDate)[DueDate]
,ISNULL(Receivables.TotalAmount_Amount,LeasePaymentSchedules.Amount_Amount) AS [ReceivableAmount_Amount]
,LeasePaymentSchedules.VATAmount_Amount AS [ProjectedVATAmount_Amount]
,ReceivableTaxes.Amount_Amount AS [ActualVATAmount_Amount]
,ISNULL(Receivables.TotalBalance_Amount,0.00 )+ ISNULL(ReceivableTaxes.Balance_Amount,0.00) AS [TotalBalance_Amount]
,CAST((CASE WHEN ReceivableTaxes.Id IS NOT NULL THEN 1 ELSE 0 END)AS BIT) AS [IsTaxAssessed]
,ReceivableTypes.[Name] AS [ReceivableType]
,LeasePaymentSchedules.PaymentType
FROM
LeasePaymentSchedules
INNER JOIN LeaseFinances ON LeaseFinances.Id = LeasePaymentSchedules.LeaseFinanceDetailId AND LeasePaymentSchedules.IsActive = 1
LEFT JOIN Receivables ON Receivables.PaymentScheduleId = LeasePaymentSchedules.Id AND Receivables.SourceTable = '_'
AND Receivables.IsActive=1
LEFT JOIN ReceivableCodes ON  Receivables.ReceivableCodeId = ReceivableCodes.Id
LEFT JOIN ReceivableTypes ON  ReceivableCodes.ReceivableTypeId = ReceivableTypes.Id
LEFT JOIN ReceivableTaxes ON Receivables.Id=ReceivableTaxes.ReceivableId AND ReceivableTaxes.IsActive=1
WHERE
 (Receivables.Id IS NOT NULL OR LeaseFinances.Id = @LeaseFinanceId)
AND (Receivables.EntityId IS NULL OR Receivables.EntityId = @ContractId)
AND (Receivables.EntityType IS NULL OR Receivables.EntityType = @ReceivableEntityType)
AND (Receivables.IsActive IS NULL OR Receivables.IsActive=1)

--Additional charge
INSERT INTO #VATReceivableInfo
(
LeaseFinanceId
,SourceId
,SourceType
,ReceivableId
,DueDate
,ReceivableAmount_Amount
,ProjectedVATAmount_Amount
,ActualVATAmount_Amount
,TotalBalance_Amount
,IsTaxAssessed
,ReceivableType
,IsAdditionalChargeNewlyAdded
,AdditionalChargeProcessedThroughDate
)
SELECT
LeaseFinanceAdditionalCharges.LeaseFinanceId
,LeaseFinanceAdditionalCharges.AdditionalChargeId AS [SourceId]
,@AdditionalChargeSourceType AS [SourceType]
,(CASE WHEN Receivables.Id IS NOT NULL THEN Receivables.Id ELSE NULL END) AS [ReceivableId]
,LeaseFinanceAdditionalChargeVATInfoes.DueDate AS [DueDate]
,ISNULL(Receivables.TotalAmount_Amount,AdditionalCharges.Amount_Amount) AS [ReceivableAmount_Amount]
,LeaseFinanceAdditionalChargeVATInfoes.VATAmount_Amount AS [ProjectedVATAmount_Amount]
, ReceivableTaxes.Amount_Amount AS [ActualVATAmount_Amount]
,ISNULL(Receivables.TotalBalance_Amount,0.00 )+ ISNULL(ReceivableTaxes.Balance_Amount,0.00) AS [TotalBalance_Amount]
,CAST((CASE WHEN ReceivableTaxes.Id IS NOT NULL THEN 1 ELSE 0 END)AS BIT) AS [IsTaxAssessed]
,ReceivableTypes.[Name] [ReceivableType]
,CASE 
	WHEN (LeaseFinanceAdditionalCharges.SundryId IS NULL AND  LeaseFinanceAdditionalCharges.RecurringSundryId IS NULL)
	THEN 1 ELSE 0 END [IsAdditionalChargeNewlyAdded]
,ISNULL(SundryRecurrings.ProcessThroughDate,DATEADD(dd,-1,SundryRecurrings.FirstDueDate))[AdditionalChargeProcessedThroughDate]
FROM
AdditionalCharges
INNER JOIN ReceivableCodes ON AdditionalCharges.ReceivableCodeId=ReceivableCodes.Id
INNER JOIN ReceivableTypes ON ReceivableCodes.ReceivableTypeId=ReceivableTypes.Id
INNER JOIN LeaseFinanceAdditionalCharges ON LeaseFinanceAdditionalCharges.AdditionalChargeId = AdditionalCharges.Id
INNER JOIN LeaseFinances ON LeaseFinances.Id = LeaseFinanceAdditionalCharges.LeaseFinanceId
INNER JOIN LeaseFinanceAdditionalChargeVATInfoes ON LeaseFinanceAdditionalCharges.Id = LeaseFinanceAdditionalChargeVATInfoes.LeaseFinanceAdditionalChargeId
AND LeaseFinanceAdditionalChargeVATInfoes.IsActive=1 
LEFT JOIN SundryRecurrings ON SundryRecurrings.Id = LeaseFinanceAdditionalCharges.RecurringSundryId
LEFT JOIN SundryRecurringPaymentSchedules ON SundryRecurringPaymentSchedules.SundryRecurringId = SundryRecurrings.Id
AND LeaseFinanceAdditionalChargeVATInfoes.DueDate = SundryRecurringPaymentSchedules.DueDate
LEFT JOIN Sundries ON Sundries.Id = LeaseFinanceAdditionalCharges.SundryId
LEFT JOIN Receivables
ON
(Receivables.SourceId = Sundries.Id 
AND Receivables.DueDate = LeaseFinanceAdditionalChargeVATInfoes.DueDate 
AND Receivables.SourceTable = @SundrySourceType
AND LeaseFinances.BookingStatus IN ('Commenced','FullyPaidOff')
)
OR
(Receivables.SourceId = SundryRecurringPaymentSchedules.Id 
AND Receivables.DueDate = LeaseFinanceAdditionalChargeVATInfoes.DueDate
AND Receivables.SourceTable = @SundryRecurringSourceType
AND LeaseFinances.BookingStatus IN ('Commenced','FullyPaidOff')
)
LEFT JOIN ReceivableTaxes ON Receivables.Id=ReceivableTaxes.ReceivableId AND ReceivableTaxes.IsActive=1
WHERE
((Receivables.EntityId = @ContractId  ) OR LeaseFinances.Id = @LeaseFinanceId)


--Blended Items
INSERT INTO #VATReceivableInfo
(
LeaseFinanceId
,SourceId
,SourceType
,ReceivableId
,DueDate
,ReceivableAmount_Amount
,ProjectedVATAmount_Amount
,ActualVATAmount_Amount
,TotalBalance_Amount
,IsTaxAssessed
,ReceivableType
,ParentBlendedItemId
)
SELECT
LeaseBlendedItems.LeaseFinanceId
,LeaseBlendedItems.BlendedItemId[SourceId]
,@BlendedItemSourceType [SourceType]
,Receivables.Id [ReceivableId]
,ISNULL(Receivables.DueDate,LeaseBlendedItemVATInfoes.DueDate)[DueDate]
,ISNULL(Receivables.TotalAmount_Amount,LeaseBlendedItemVATInfoes.Amount_Amount) AS [ReceivableAmount_Amount]
,LeaseBlendedItemVATInfoes.VATAmount_Amount AS [ProjectedVATAmount_Amount]
,ReceivableTaxes.Amount_Amount AS [ActualVATAmount_Amount]
,ISNULL(Receivables.TotalBalance_Amount,0.00 )+ ISNULL(ReceivableTaxes.Balance_Amount,0.00) AS [TotalBalance_Amount]
,CAST((CASE WHEN ReceivableTaxes.Id IS NOT NULL THEN 1 ELSE 0 END)AS BIT) AS [IsTaxAssessed]
,ReceivableTypes.[Name] AS [ReceivableType]
,BlendedItems.ParentBlendedItemId

FROM
BlendedItems
INNER JOIN LeaseBlendedItems ON BlendedItems.Id = LeaseBlendedItems.BlendedItemId
INNER JOIN LeaseFinances ON LeaseBlendedItems.LeaseFinanceId = LeaseFinances.Id
INNER JOIN LeaseBlendedItemVATInfoes ON LeaseBlendedItems.Id = LeaseBlendedItemVATInfoes.LeaseBlendedItemId AND LeaseBlendedItemVATInfoes.IsActive=1
INNER JOIN ReceivableCodes ON BlendedItems.ReceivableCodeId=ReceivableCodes.Id
INNER JOIN ReceivableTypes ON ReceivableCodes.ReceivableTypeId=ReceivableTypes.Id
LEFT JOIN BlendedItemDetails ON BlendedItemDetails.BlendedItemId=LeaseBlendedItems.BlendedItemId
--AND LeaseBlendedItemVATInfoes.DueDate=BlendedItemDetails.DueDate/*This is commented because BIDetails.DueDate never matches with Receivable.DueDate when StartDate != DueDate*/
LEFT JOIN Sundries ON BlendedItemDetails.SundryId = Sundries.Id 
LEFT JOIN Receivables ON Receivables.SourceId = Sundries.Id AND Receivables.SourceTable = @SundrySourceType
AND LeaseBlendedItemVATInfoes.DueDate=Receivables.DueDate
LEFT JOIN ReceivableTaxes ON Receivables.Id=ReceivableTaxes.ReceivableId AND ReceivableTaxes.IsActive=1
WHERE
(Receivables.EntityId = @ContractId OR LeaseFinances.Id = @LeaseFinanceId)
--Security Deposits
INSERT INTO #VATReceivableInfo
(
 LeaseFinanceId
,ReceivableId
,SourceId
,SourceType
,DueDate
,ReceivableAmount_Amount
,ProjectedVATAmount_Amount
,ActualVATAmount_Amount
,TotalBalance_Amount
,IsTaxAssessed
,ReceivableType
)
SELECT
@LeaseFinanceId,
SecurityDeposits.ReceivableId,
SecurityDeposits.Id [SourceId],
@SecurityDepositSourceType [SourceType],
Receivables.DueDate,
Receivables.TotalAmount_Amount[ReceivableAmount_Amount],
SecurityDeposits.ProjectedVATAmount_Amount,
ReceivableTaxes.Amount_Amount AS [ActualVATAmount_Amount],
ISNULL(Receivables.TotalBalance_Amount,0.00 )+ ISNULL(ReceivableTaxes.Balance_Amount,0.00) AS [TotalBalance_Amount],
CAST((CASE WHEN ReceivableTaxes.Id IS NOT NULL THEN 1 ELSE 0 END)AS BIT)[IsTaxAssessed],
ReceivableTypes.Name[ReceivableType]
FROM
SecurityDeposits
INNER JOIN Receivables ON SecurityDeposits.ReceivableId=Receivables.Id AND Receivables.IsActive=1
INNER JOIN ReceivableCodes ON SecurityDeposits.ReceivableCodeId=ReceivableCodes.Id
INNER JOIN ReceivableTypes ON ReceivableCodes.ReceivableTypeId=ReceivableTypes.Id
LEFT JOIN ReceivableTaxes ON Receivables.Id=ReceivableTaxes.ReceivableId AND ReceivableTaxes.IsActive=1
WHERE
SecurityDeposits.ContractId=@ContractId
AND SecurityDeposits.EntityType=@ReceivableEntityType
AND SecurityDeposits.IsActive=1

--PayOff receivables
INSERT INTO #VATReceivableInfo
(
LeaseFinanceId
,SourceId
,SourceType
,ReceivableId
,DueDate
,ReceivableAmount_Amount
,ProjectedVATAmount_Amount
,ActualVATAmount_Amount
,TotalBalance_Amount
,IsTaxAssessed
,ReceivableType
)
SELECT
 @LeaseFinanceId
,PayOffs.Id[SourceId]
,@PayOffSourceType AS [SourceType]
,Receivables.Id AS [ReceivableId]
,Receivables.DueDate
,Receivables.TotalAmount_Amount AS [ReceivableAmount_Amount]
,CASE 
	WHEN ReceivableTypes.Name='LeasePayOff'
		THEN PayOffs.PayoffVATAmount_Amount
	WHEN ReceivableTypes.Name='BuyOut'
		THEN PayOffs.BuyOutVATAmount_Amount
END AS [ProjectedVATAmount_Amount]
,ReceivableTaxes.Amount_Amount AS [ActualVATAmount_Amount]
,ISNULL(Receivables.TotalBalance_Amount,0.00 )+ ISNULL(ReceivableTaxes.Balance_Amount,0.00) AS [TotalBalance_Amount]
,CAST((CASE WHEN ReceivableTaxes.Id IS NOT NULL THEN 1 ELSE 0 END)AS BIT)AS [IsTaxAssessed]
,ReceivableTypes.[Name] AS [ReceivableType]
FROM
LeaseFinances
INNER JOIN PayOffs ON LeaseFinances.Id = PayOffs.LeaseFinanceId
INNER JOIN Receivables ON PayOffs.Id=Receivables.SourceId
INNER JOIN ReceivableCodes ON Receivables.ReceivableCodeId = ReceivableCodes.Id
INNER JOIN ReceivableTypes ON ReceivableCodes.ReceivableTypeId = ReceivableTypes.Id
LEFT JOIN ReceivableTaxes ON Receivables.Id=ReceivableTaxes.ReceivableId AND ReceivableTaxes.IsActive=1
WHERE
LeaseFinances.ContractId = @ContractId
AND Receivables.IsActive=1
AND Receivables.SourceTable='LeasePayoff'
--PayOff sundry's receivables
UPDATE #VATReceivableInfo
	SET ProjectedVATAmount_Amount = PayoffSundries.VATAmount_Amount
FROM #VATReceivableInfo
INNER JOIN Receivables ON #VATReceivableInfo.ReceivableId=Receivables.Id AND Receivables.IsActive=1
INNER JOIN Sundries ON Receivables.Id=Sundries.ReceivableId AND Sundries.IsActive=1
INNER JOIN PayoffSundries ON PayoffSundries.SundryId=Sundries.Id AND PayoffSundries.IsActive=1 AND Sundries.IsActive=1

--Outside contract Onetime Receivable
SELECT
	Temp_InContractSundryDetails.SundryId,	
	Temp_InContractSundryDetails.RecurringSundryId
INTO #InContractSundryDetails
FROM 
(
SELECT
	LeaseFinanceAdditionalCharges.SundryId,LeaseFinanceAdditionalCharges.RecurringSundryId
FROM LeaseFinanceAdditionalCharges
JOIN LeaseFinances ON LeaseFinanceAdditionalCharges.LeaseFinanceId=LeaseFinances.Id
JOIN Contracts ON  LeaseFinances.ContractId = Contracts.Id
WHERE LeaseFinances.ContractId = @ContractId 
UNION
SELECT
	BlendedItemDetails.SundryId,NULL [RecurringSundryId]
FROM #VATReceivableInfo
JOIN BlendedItemDetails ON #VATReceivableInfo.SourceId=BlendedItemDetails.BlendedItemId 
AND #VATReceivableInfo.SourceType=@BlendedItemSourceType
UNION 
SELECT 
	PayoffSundries.SundryId,NULL [RecurringSundryId]
FROM PayoffSundries
)Temp_InContractSundryDetails

INSERT INTO #VATReceivableInfo
(
LeaseFinanceId
,SourceId
,SourceType
,ReceivableId
,DueDate
,ReceivableAmount_Amount
,ProjectedVATAmount_Amount
,ActualVATAmount_Amount
,TotalBalance_Amount
,IsTaxAssessed
,ReceivableType
)

SELECT
	@LeaseFinanceId,
	Sundries.Id [SourceId],
	@SundrySourceType [SourceType],
	Sundries.ReceivableId,
	Receivables.DueDate,
	Receivables.TotalAmount_Amount[ReceivableAmount_Amount],
	Sundries.ProjectedVATAmount_Amount,
	ReceivableTaxes.Amount_Amount AS [ActualVATAmount_Amount],
	ISNULL(Receivables.TotalBalance_Amount,0.00 )+ ISNULL(ReceivableTaxes.Balance_Amount,0.00) AS [TotalBalance_Amount],
	CAST((CASE WHEN ReceivableTaxes.Id IS NOT NULL THEN 1 ELSE 0 END)AS BIT)[IsTaxAssessed],
	ReceivableTypes.Name[ReceivableType]
FROM Receivables
INNER JOIN Sundries ON Sundries.ReceivableId=Receivables.Id AND Receivables.IsActive=1
INNER JOIN ReceivableCodes ON Sundries.ReceivableCodeId=ReceivableCodes.Id
INNER JOIN ReceivableTypes ON ReceivableCodes.ReceivableTypeId=ReceivableTypes.Id
LEFT JOIN ReceivableTaxes ON Receivables.Id=ReceivableTaxes.ReceivableId AND ReceivableTaxes.IsActive=1
LEFT JOIN(SELECT SundryId FROM #InContractSundryDetails WHERE SundryId IS NOT NULL)tempSundries ON Sundries.Id=tempSundries.SundryId
WHERE
Receivables.EntityId = @ContractId
AND Receivables.EntityType = @ReceivableEntityType
AND Receivables.IsActive=1
AND tempSundries.SundryId IS NULL

INSERT INTO #VATReceivableInfo
(
LeaseFinanceId
,SourceId
,SourceType
,ReceivableId
,DueDate
,ReceivableAmount_Amount
,ProjectedVATAmount_Amount
,ActualVATAmount_Amount
,TotalBalance_Amount
,IsTaxAssessed
,ReceivableType
)

SELECT
	@LeaseFinanceId,
	SundryRecurringPaymentSchedules.Id [SourceId],
	@SundryRecurringSourceType [SourceType],
	SundryRecurringPaymentSchedules.ReceivableId,
	ISNULL(Receivables.DueDate,SundryRecurringPaymentSchedules.DueDate)[DueDate],
	ISNULL(Receivables.TotalAmount_Amount, SundryRecurringPaymentSchedules.Amount_Amount)[ReceivableAmount_Amount],
	SundryRecurringPaymentSchedules.ProjectedVATAmount_Amount,
	ReceivableTaxes.Amount_Amount AS [ActualVATAmount_Amount],
	ISNULL(Receivables.TotalBalance_Amount,0.00 )+ ISNULL(ReceivableTaxes.Balance_Amount,0.00) AS [TotalBalance_Amount],
	CAST((CASE WHEN ReceivableTaxes.Id IS NOT NULL THEN 1 ELSE 0 END)AS BIT)[IsTaxAssessed],
	ReceivableTypes.Name[ReceivableType]
FROM SundryRecurringPaymentSchedules
INNER JOIN SundryRecurrings ON SundryRecurringPaymentSchedules.SundryRecurringId = SundryRecurrings.Id
AND SundryRecurringPaymentSchedules.IsActive=1 AND SundryRecurrings.IsActive=1
INNER JOIN ReceivableCodes ON SundryRecurrings.ReceivableCodeId=ReceivableCodes.Id
INNER JOIN ReceivableTypes ON ReceivableCodes.ReceivableTypeId=ReceivableTypes.Id
LEFT JOIN Receivables ON SundryRecurringPaymentSchedules.ReceivableId = Receivables.Id
AND Receivables.IsActive=1 AND Receivables.SourceTable = @SundryRecurringSourceType
LEFT JOIN ReceivableTaxes ON Receivables.Id=ReceivableTaxes.ReceivableId AND ReceivableTaxes.IsActive=1
LEFT JOIN(SELECT RecurringSundryId FROM #InContractSundryDetails WHERE RecurringSundryId IS NOT NULL)tempSundries 
ON SundryRecurrings.Id=tempSundries.RecurringSundryId
WHERE
SundryRecurrings.ContractId = @ContractId
AND SundryRecurrings.EntityType = @ReceivableEntityType
AND tempSundries.RecurringSundryId IS NULL


SELECT 
ReceivableDetails.ReceivableId[OriginalReceivableIds],
AdjustmentReceivableDetails.ReceivableId[AdjustmentReceivableId]
	INTO #OriginalAndAdjustedReceivables
FROM #VATReceivableInfo
INNER JOIN ReceivableDetails ON #VATReceivableInfo.ReceivableId = ReceivableDetails.ReceivableId
INNER JOIN ReceivableDetails AdjustmentReceivableDetails ON ReceivableDetails.Id=AdjustmentReceivableDetails.AdjustmentBasisReceivableDetailId
AND ReceivableDetails.IsActive = 1 AND AdjustmentReceivableDetails.IsActive = 1 AND #VATReceivableInfo.ReceivableId IS NOT NULL
WHERE ISNULL(ReceivableDetails.AdjustmentBasisReceivableDetailId,AdjustmentReceivableDetails.Id) IS NOT NULL
GROUP BY ReceivableDetails.ReceivableId,AdjustmentReceivableDetails.ReceivableId

UPDATE #VATReceivableInfo
SET IsAdjustmentReceivable = 1,
ProjectedVATAmount_Amount =
	 CASE WHEN #VATReceivableInfo.ReceivableAmount_Amount < 0
		THEN ProjectedVATAmount_Amount*(-1)
	ELSE ProjectedVATAmount_Amount END
FROM #VATReceivableInfo
LEFT JOIN 
(
SELECT OriginalReceivableIds[ReceivableId] FROM #OriginalAndAdjustedReceivables 
UNION
SELECT AdjustmentReceivableId[ReceivableId] FROM #OriginalAndAdjustedReceivables
)TempReceivableIds
ON #VATReceivableInfo.ReceivableId = TempReceivableIds.ReceivableId
WHERE TempReceivableIds.ReceivableId IS NOT NULL

UPDATE
#VATReceivableInfo
SET
TotalBalance_Amount = CASE WHEN IsTaxAssessed = 0 
							THEN  ReceivableAmount_Amount + ISNULL(ProjectedVATAmount_Amount,0.00) 
					ELSE TotalBalance_Amount END,
TotalAmount_Amount = ReceivableAmount_Amount + ISNULL(ActualVATAmount_Amount,ProjectedVATAmount_Amount)

IF (@EffectiveDate IS NULL)
BEGIN
SELECT DISTINCT
SourceId
,ISNULL(SourceType ,'_')[SourceType]
,ReceivableId
,DueDate
,ReceivableAmount_Amount
,@ContractCurrency ReceivableAmount_Currency
,ProjectedVATAmount_Amount
,@ContractCurrency ProjectedVATAmount_Currency
,ISNULL(ActualVATAmount_Amount,0.00) AssessedTax_Amount
,@ContractCurrency AssessedTax_Currency
,TotalBalance_Amount
,@ContractCurrency TotalBalance_Currency
,TotalAmount_Amount
,@ContractCurrency TotalAmount_Currency
,IsTaxAssessed
,IsAdjustmentReceivable
,ISNULL(ReceivableType,'_')ReceivableType
,PaymentType
FROM #VATReceivableInfo
WHERE (LeaseFinanceId = @LeaseFinanceId OR IsAdjustmentReceivable = 1 )
END
ELSE
BEGIN
--Update unscheduled OTP's projected VAT from current finance object
UPDATE #VATReceivableInfo
	SET ProjectedVATAmount_Amount= ProjectedVATOnUnscheduledOTP.ProjectedVATAmount_Amount
FROM #VATReceivableInfo
JOIN LeaseFinanceDetails ON #VATReceivableInfo.LeaseFinanceId = LeaseFinanceDetails.Id
LEFT JOIN (
SELECT 
	LeaseFinanceId,
	DueDate,
	PaymentType,
	ProjectedVATAmount_Amount 
FROM #VATReceivableInfo WHERE  PaymentType IN(@OverTermPaymentType,@SupplementPaymentType)
AND LeaseFinanceId = @LeaseFinanceId
)ProjectedVATOnUnscheduledOTP
ON #VATReceivableInfo.DueDate = ProjectedVATOnUnscheduledOTP.DueDate
AND #VATReceivableInfo.PaymentType = ProjectedVATOnUnscheduledOTP.PaymentType
AND #VATReceivableInfo.IsAdjustmentReceivable IS NULL
WHERE LeaseFinanceDetails.IsOTPScheduled = 0 AND #VATReceivableInfo.PaymentType IN(@OverTermPaymentType,@SupplementPaymentType)

SELECT  
CASE
	WHEN LeaseBlendedItems.Revise =1 OR ParentOfRevisedBI.Revise =1 THEN 1 
ELSE 0 END[Revise],
CASE
	WHEN LeaseBlendedItems.Revise = 1 AND DueDate >= @EffectiveDate THEN SourceId 
	WHEN LeaseBlendedItems.Revise = 1 AND DueDate < @EffectiveDate THEN #VATReceivableInfo.ParentBlendedItemId
	WHEN LeaseBlendedItems.Revise IS NULL  THEN #VATReceivableInfo.ParentBlendedItemId
ELSE #VATReceivableInfo.ParentBlendedItemId END [NewSourceId],
#VATReceivableInfo.LeaseFinanceId ,
#VATReceivableInfo.SourceId ,
#VATReceivableInfo.SourceType ,
#VATReceivableInfo.ReceivableId ,
#VATReceivableInfo.DueDate ,
#VATReceivableInfo.ReceivableAmount_Amount ,
#VATReceivableInfo.ProjectedVATAmount_Amount ,
#VATReceivableInfo.ActualVATAmount_Amount ,
#VATReceivableInfo.TotalAmount_Amount ,
#VATReceivableInfo.TotalBalance_Amount,
#VATReceivableInfo.IsTaxAssessed ,
#VATReceivableInfo.IsAdjustmentReceivable,
#VATReceivableInfo.ReceivableType ,
#VATReceivableInfo.PaymentType ,
#VATReceivableInfo.ParentBlendedItemId 
INTO #BlendedItemVATReceivableInfoOnRestructure
FROM #VATReceivableInfo
LEFT JOIN LeaseBlendedItems 
ON #VATReceivableInfo.LeaseFinanceId = LeaseBlendedItems.LeaseFinanceId AND #VATReceivableInfo.LeaseFinanceId=@LeaseFinanceId
AND #VATReceivableInfo.SourceId = LeaseBlendedItems.BlendedItemId
LEFT JOIN 
(
SELECT
	BlendedItems.ParentBlendedItemId,
	LeaseBlendedItems.Revise
FROM LeaseBlendedItems 
LEFT JOIN BlendedItems 
ON LeaseBlendedItems.BlendedItemId = BlendedItems.Id
WHERE LeaseFinanceId=@LeaseFinanceId AND Revise=1
)ParentOfRevisedBI
ON #VATReceivableInfo.SourceId = ParentOfRevisedBI.ParentBlendedItemId
WHERE SourceType = @BlendedItemSourceType

SELECT DISTINCT
LeaseFinanceId,
SourceId
,ISNULL(SourceType ,'_')[SourceType]
,ReceivableId
,DueDate
,ReceivableAmount_Amount
,@ContractCurrency ReceivableAmount_Currency
,ProjectedVATAmount_Amount
,@ContractCurrency ProjectedVATAmount_Currency
,ISNULL(ActualVATAmount_Amount,0.00) AssessedTax_Amount
,@ContractCurrency AssessedTax_Currency
,TotalBalance_Amount
,@ContractCurrency TotalBalance_Currency
,TotalAmount_Amount
,@ContractCurrency TotalAmount_Currency
,IsTaxAssessed
,IsAdjustmentReceivable
,ISNULL(ReceivableType,'_')ReceivableType
,PaymentType
FROM #VATReceivableInfo
WHERE 
((LeaseFinanceId = @LeaseFinanceId AND DueDate > @EffectiveDate AND PaymentType NOT IN (@InterimRentPaymentType,@InterimInterestPaymentType) )
OR (LeaseFinanceId != @LeaseFinanceId AND (DueDate <= @EffectiveDate  OR PaymentType IN (@InterimRentPaymentType,@InterimInterestPaymentType)))
OR IsAdjustmentReceivable = 1 
OR SourceType IN( @PayOffSourceType, @SecurityDepositSourceType,@SundryRecurringSourceType,@SundrySourceType))
AND SourceType NOT IN(@AdditionalChargeSourceType, @BlendedItemSourceType)

UNION ALL

SELECT DISTINCT
LeaseFinanceId,
SourceId
,ISNULL(SourceType ,'_')[SourceType]
,ReceivableId
,DueDate
,ReceivableAmount_Amount
,@ContractCurrency ReceivableAmount_Currency
,ProjectedVATAmount_Amount
,@ContractCurrency ProjectedVATAmount_Currency
,ISNULL(ActualVATAmount_Amount,0.00) AssessedTax_Amount
,@ContractCurrency AssessedTax_Currency
,TotalBalance_Amount
,@ContractCurrency TotalBalance_Currency
,TotalAmount_Amount
,@ContractCurrency TotalAmount_Currency
,IsTaxAssessed
,IsAdjustmentReceivable
,ISNULL(ReceivableType,'_')ReceivableType
,PaymentType
FROM #VATReceivableInfo
WHERE #VATReceivableInfo.SourceType = @AdditionalChargeSourceType
AND
(
(LeaseFinanceId = @LeaseFinanceId AND (IsAdditionalChargeNewlyAdded = 1 OR @IsRestructureAtInception = 1 
OR (DueDate > AdditionalChargeProcessedThroughDate)))
OR
(LeaseFinanceId != @LeaseFinanceId AND @IsRestructureAtInception = 0 )
OR
 IsAdjustmentReceivable = 1 
)

UNION ALL

SELECT DISTINCT
LeaseFinanceId,
SourceId
,ISNULL(SourceType ,'_')[SourceType]
,ReceivableId
,DueDate
,ReceivableAmount_Amount
,@ContractCurrency ReceivableAmount_Currency
,ProjectedVATAmount_Amount
,@ContractCurrency ProjectedVATAmount_Currency
,ISNULL(ActualVATAmount_Amount,0.00) AssessedTax_Amount
,@ContractCurrency AssessedTax_Currency
,TotalBalance_Amount
,@ContractCurrency TotalBalance_Currency
,TotalAmount_Amount
,@ContractCurrency TotalAmount_Currency
,IsTaxAssessed
,IsAdjustmentReceivable
,ISNULL(ReceivableType,'_')ReceivableType
,PaymentType
FROM #BlendedItemVATReceivableInfoOnRestructure
WHERE
SourceType = @BlendedItemSourceType
AND
(IsAdjustmentReceivable = 1 
OR
((LeaseFinanceId = @LeaseFinanceId AND( NewSourceId IS NULL OR NewSourceId = SourceId))
OR (LeaseFinanceId = @PreviousLeaseFinanceId 
AND ((Revise=1 AND DueDate < @EffectiveDate) OR Revise = 0))))
END
END

GO
