SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[UpdateNonDSLReceivablesForReceiptApplication] 
( @ReceiptId bigint
, @CurrentUserId bigint
, @ApplicationId bigint
, @CurrentTime datetimeoffset
, @ContractId bigint
, @UpdateBalance bit
, @IsReversal bit
, @ReceivedDate date)
AS
BEGIN
SET NOCOUNT ON
DECLARE @MaxPaymentScheduleId bigint
SELECT
@MaxPaymentScheduleId = MAX(LoanPaymentSchedules.Id)
FROM LoanPaymentSchedules
INNER JOIN LoanFinances
ON LoanPaymentSchedules.LoanFinanceId = LoanFinances.Id
WHERE contractid = @ContractId
GROUP BY ContractId
CREATE TABLE #MaxRecDetailIdToExclude (
ReceivableDetailID bigint
)

CREATE TABLE #UpdateReceivableInvoice (
ReceivableInvoiceId bigint
)


	UPDATE ReceivableDetailsWithholdingTaxDetails
	SET
		EffectiveBalance_Amount = EffectiveBalance_Amount + AdjustedWithholdingTax_Amount,
		Balance_Amount = ReceivableDetailsWithholdingTaxDetails.Balance_Amount +
			CASE
				WHEN Receipts.Status IN ('Posted', 'Completed') THEN AdjustedWithholdingTax_Amount
				ELSE 0
			END,
		UpdatedById = @CurrentUserId,
		UpdatedTime = @CurrentTime
	OUTPUT inserted.ReceivableWithholdingTaxDetailId
	FROM ReceiptApplicationReceivableDetails
	JOIN ReceivableDetailsWithholdingTaxDetails ON ReceiptApplicationReceivableDetails.ReceivableDetailId = ReceivableDetailsWithholdingTaxDetails.ReceivableDetailId
	JOIN ReceiptApplications ON ReceiptApplicationReceivableDetails.ReceiptApplicationId = ReceiptApplications.Id
	JOIN Receipts ON ReceiptApplications.ReceiptId = Receipts.Id
	WHERE ReceiptApplicationReceivableDetails.ReceiptApplicationId = @ApplicationId AND (ReceiptApplicationReceivableDetails.IsActive = 0 OR @IsReversal = 1)

	;WITH WHTBalanceInfo AS
	(
		SELECT 
			ReceivableWithholdingTaxDetails.ReceivableId,
			SUM(ReceivableDetailsWithholdingTaxDetails.Balance_Amount) as TotalWHTBalance,
			SUM(ReceivableDetailsWithholdingTaxDetails.EffectiveBalance_Amount) as TotalWHTEffectiveBalance
		FROM ReceivableWithholdingTaxDetails
		INNER JOIN ReceivableDetailsWithholdingTaxDetails ON ReceivableWithholdingTaxDetails.Id = ReceivableDetailsWithholdingTaxDetails.ReceivableWithholdingTaxDetailId
		INNER JOIN ReceiptApplicationReceivableDetails ON ReceivableDetailsWithholdingTaxDetails.ReceivableDetailId = ReceiptApplicationReceivableDetails.ReceivableDetailId
		WHERE ReceiptApplicationReceivableDetails.ReceiptApplicationId = @ApplicationId AND (ReceiptApplicationReceivableDetails.IsActive = 0 OR @IsReversal = 1)
		GROUP BY ReceivableWithholdingTaxDetails.ReceivableId
	)
	UPDATE ReceivableWithholdingTaxDetails
	SET
		Balance_Amount = TotalWHTBalance,
		EffectiveBalance_Amount = TotalWHTEffectiveBalance,
		UpdatedById = @CurrentUserId,
		UpdatedTime = @CurrentTime
	FROM ReceivableWithholdingTaxDetails
	JOIN WHTBalanceInfo ON ReceivableWithholdingTaxDetails.ReceivableId = WHTBalanceInfo.ReceivableId

IF (@IsReversal = 1)
BEGIN

UPDATE ReceivableInvoiceReceiptDetails
SET AmountApplied_Amount = 0.0,
TaxApplied_Amount = 0.0,
IsActive = 0,
UpdatedById = @CurrentUserId,
UpdatedTime = @CurrentTime
WHERE ReceiptId = @ReceiptId;
SELECT
ReceivableInvoiceId
INTO #TempReceivableInvoice
FROM ReceiptApplicationReceivableDetails
INNER JOIN ReceiptApplications
ON ReceiptApplications.Id = ReceiptApplicationReceivableDetails.ReceiptApplicationId
WHERE ReceiptApplications.ReceiptId = @ReceiptId
AND ReceiptApplicationReceivableDetails.ReceivableInvoiceId IS NOT NULL
UPDATE ReceivableInvoices
SET LastReceivedDate = NULL,
UpdatedById = @CurrentUserId,
UpdatedTime = @CurrentTime
FROM ReceivableInvoices
INNER JOIN #TempReceivableInvoice
ON #TempReceivableInvoice.ReceivableInvoiceId = ReceivableInvoices.Id
UPDATE ReceivableInvoices
SET LastReceivedDate = LastReceivedDateDetails.LastReceivedDate,
UpdatedById = @CurrentUserId,
UpdatedTime = @CurrentTime
FROM ReceivableInvoices
INNER JOIN (SELECT
ReceivableInvoiceReceiptDetails.ReceivableInvoiceId AS ReceivableInvoiceId,
MAX(ReceivableInvoiceReceiptDetails.ReceivedDate) AS LastReceivedDate
FROM ReceivableInvoiceReceiptDetails
INNER JOIN #TempReceivableInvoice
ON #TempReceivableInvoice.ReceivableInvoiceId = ReceivableInvoiceReceiptDetails.ReceivableInvoiceId
WHERE ReceivableInvoiceReceiptDetails.IsActive = 1
AND (ReceivableInvoiceReceiptDetails.AmountApplied_Amount != 0
OR ReceivableInvoiceReceiptDetails.TaxApplied_Amount != 0)
GROUP BY ReceivableInvoiceReceiptDetails.ReceivableInvoiceId) AS LastReceivedDateDetails
ON LastReceivedDateDetails.ReceivableInvoiceId = ReceivableInvoices.Id
DROP TABLE #TempReceivableInvoice
SELECT
ReceiptApplicationReceivableDetails.ReceivableDetailId,
ReceivableTypes.Name AS ReceivableTypeName,
Receivables.DueDate,
Receivables.TotalBalance_Amount,
ReceiptApplicationReceivableDetails.BookAmountApplied_Amount,
ReceivableDetails.amount_Amount,
ReceivableDetails.EffectiveBookBalance_Amount
INTO #ReceivableDetails
FROM ReceiptApplicationReceivableDetails
INNER JOIN ReceiptApplications
ON ReceiptApplicationReceivableDetails.ReceiptApplicationId = ReceiptApplications.Id
INNER JOIN Receipts
ON ReceiptApplications.ReceiptId = Receipts.Id
INNER JOIN receivabledetails
ON ReceiptApplicationReceivableDetails.receivabledetailid = receivabledetails.Id
INNER JOIN Receivables
ON ReceivableDetails.ReceivableId = Receivables.id
INNER JOIN ReceivableCodes
ON Receivables.ReceivableCodeId = ReceivableCodes.Id
INNER JOIN ReceivableTypes
ON ReceivableCodes.ReceivableTypeId = ReceivableTypes.Id
WHERE Receipts.ContractId = @ContractId
AND ReceiptApplications.Id = @ApplicationId
AND ReceiptApplicationReceivableDetails.IsActive = 1
AND receivabledetails.IsActive=1
AND Receivables.IsActive=1
SELECT
ReceiptApplicationReceivableDetails.ReceivableDetailId,
SUM(ReceiptApplicationReceivableDetails.AmountApplied_Amount) AS TotalAmountApplied,
SUM(ReceiptApplicationReceivableDetails.BookAmountApplied_Amount) AS TotalBookAmountApplied,
SUM(ReceiptApplicationReceivableDetails.LeaseComponentAmountApplied_Amount) AS TotalLeaseComponentAmountApplied,
SUM(ReceiptApplicationReceivableDetails.NonLeaseComponentAmountApplied_Amount) AS TotalNonLeaseComponentAmountApplied
INTO #PreviousReceiptAppliedDetails
FROM ReceiptApplicationReceivableDetails
INNER JOIN ReceiptApplications
ON ReceiptApplicationReceivableDetails.ReceiptApplicationId = ReceiptApplications.Id
INNER JOIN Receipts
ON ReceiptApplications.ReceiptId = Receipts.Id
INNER JOIN #ReceivableDetails
ON ReceiptApplicationReceivableDetails.ReceivableDetailId = #ReceivableDetails.ReceivableDetailId
WHERE ReceiptApplications.Id < @ApplicationId
AND (Receipts.Status = 'Posted'
OR Receipts.Status = 'Completed')
GROUP BY ReceiptApplicationReceivableDetails.ReceivableDetailId
DECLARE @MaxDueDate datetime
SELECT
@MaxDueDate = MAX(DueDate)
FROM #ReceivableDetails
WHERE #ReceivableDetails.ReceivableTypeName = 'LoanPrincipal'
AND TotalBalance_Amount >= 0
SELECT
#ReceivableDetails.ReceivableDetailId,
#ReceivableDetails.BookAmountApplied_Amount + ISNULL(#PreviousReceiptAppliedDetails.TotalBookAmountApplied, 0.00) - #ReceivableDetails.Amount_Amount AS Balance,
#ReceivableDetails.EffectiveBookBalance_Amount,
#ReceivableDetails.BookAmountApplied_Amount,
#PreviousReceiptAppliedDetails.TotalBookAmountApplied AS PreviousBookAmountApplied
INTO #ReceiptApplicationReceivableDetails
FROM #ReceivableDetails
LEFT JOIN #PreviousReceiptAppliedDetails
ON #ReceivableDetails.ReceivableDetailId = #PreviousReceiptAppliedDetails.ReceivableDetailId
WHERE #ReceivableDetails.TotalBalance_Amount >= 0
AND DueDate = @MaxDueDate
AND #ReceivableDetails.receivabletypename = 'LoanPrincipal'
IF ((SELECT COUNT(ReceivableDetailID) FROM #ReceiptApplicationReceivableDetails WHERE EffectiveBookBalance_Amount < 0) > 0)
BEGIN
UPDATE ReceivableDetails
SET EffectiveBookBalance_Amount = ReceivableDetails.EffectiveBookBalance_Amount + #ReceiptApplicationReceivableDetails.BookAmountApplied_Amount,
UpdatedById = @CurrentUserId,
UpdatedTime = @CurrentTime
FROM ReceivableDetails
INNER JOIN #ReceiptApplicationReceivableDetails
ON ReceivableDetails.Id = #ReceiptApplicationReceivableDetails.ReceivableDetailID
WHERE #ReceiptApplicationReceivableDetails.EffectiveBookBalance_Amount < 0
AND ReceivableDetails.IsActive=1
INSERT INTO #MaxRecDetailIdToExclude
SELECT
ReceivableDetailID
FROM #ReceiptApplicationReceivableDetails
WHERE #ReceiptApplicationReceivableDetails.EffectiveBookBalance_Amount < 0
END
ELSE
IF ((SELECT COUNT(ReceivableDetailID) FROM #ReceiptApplicationReceivableDetails WHERE Balance > 0) > 0)
BEGIN
DECLARE @DueDateToUpdate datetime
DECLARE @TotalBalance decimal(16, 9)
DECLARE @TotalEffBalance decimal(16, 9)
SELECT
@TotalBalance =
CASE
WHEN SUM(#ReceiptApplicationReceivableDetails.BookAmountApplied_Amount) < SUM(Balance) THEN SUM(#ReceiptApplicationReceivableDetails.BookAmountApplied_Amount)
ELSE SUM(#ReceiptApplicationReceivableDetails.Balance)
END
FROM #ReceiptApplicationReceivableDetails
WHERE Balance > 0
SELECT TOP 1
@DueDateToUpdate = DueDate
FROM Receivables
WHERE Receivables.DueDate > @MaxDueDate
AND Receivables.EntityID = @ContractId
AND Receivables.IsActive=1
SELECT
@TotalEffBalance = SUM(EffectiveBookBalance_Amount)
FROM ReceivableDetails
INNER JOIN Receivables
ON ReceivableDetails.ReceivableId = Receivables.Id
INNER JOIN ReceivableCodes
ON Receivables.ReceivableCodeId = ReceivableCodes.Id
INNER JOIN ReceivableTypes
ON ReceivableCodes.ReceivableTypeId = ReceivableTypes.Id
WHERE receivables.TotalBalance_Amount >= 0
AND receivables.DueDate = @DueDateToUpdate
AND ReceivableTypes.Name = 'LoanPrincipal'
AND receivables.EntityId = @ContractId
AND ReceivableDetails.IsActive=1
AND Receivables.IsActive=1
UPDATE ReceivableDetails
SET EffectiveBookBalance_Amount = EffectiveBookBalance_Amount + ((EffectiveBookBalance_Amount / @TotalEffBalance) * @TotalBalance),
UpdatedById = @CurrentUserId,
UpdatedTime = @CurrentTime
FROM ReceivableDetails
INNER JOIN Receivables
ON ReceivableDetails.ReceivableId = Receivables.Id
INNER JOIN ReceivableCodes
ON Receivables.ReceivableCodeId = ReceivableCodes.Id
INNER JOIN ReceivableTypes
ON ReceivableCodes.ReceivableTypeId = ReceivableTypes.Id
WHERE receivables.TotalBalance_Amount >= 0
AND receivables.DueDate = @DueDateToUpdate
AND ReceivableTypes.Name = 'LoanPrincipal'
AND receivables.EntityId = @ContractId
AND ReceivableDetails.IsActive=1
AND Receivables.IsActive=1
INSERT INTO #MaxRecDetailIdToExclude
SELECT
ReceivableDetailID
FROM #ReceiptApplicationReceivableDetails
WHERE Balance > 0
UPDATE ReceivableDetails
SET EffectiveBookBalance_Amount =
CASE
WHEN #ReceiptApplicationReceivableDetails.PreviousBookAmountApplied IS NULL THEN ReceivableDetails.Amount_Amount
ELSE CASE
WHEN #ReceiptApplicationReceivableDetails.PreviousBookAmountApplied IS NOT NULL AND
(#ReceiptApplicationReceivableDetails.BookAmountApplied_Amount - #ReceiptApplicationReceivableDetails.Balance) > 0 THEN ReceivableDetails.EffectiveBookBalance_Amount + (#ReceiptApplicationReceivableDetails.BookAmountApplied_Amount -
#ReceiptApplicationReceivableDetails.Balance)
ELSE CASE
WHEN #ReceiptApplicationReceivableDetails.PreviousBookAmountApplied IS NOT NULL THEN 0.00
ELSE ReceivableDetails.EffectiveBookBalance_Amount
END
END
END,
UpdatedById = @CurrentUserId,
UpdatedTime = @CurrentTime
FROM ReceivableDetails
INNER JOIN ReceiptApplicationReceivableDetails
ON ReceivableDetails.Id = ReceiptApplicationReceivableDetails.ReceivableDetailId
INNER JOIN #ReceiptApplicationReceivableDetails
ON ReceivableDetails.Id = #ReceiptApplicationReceivableDetails.ReceivableDetailID
LEFT JOIN #PreviousReceiptAppliedDetails
ON ReceiptApplicationReceivableDetails.ReceivableDetailId = #PreviousReceiptAppliedDetails.ReceivableDetailId
WHERE ReceiptApplicationReceivableDetails.ReceiptApplicationId = @ApplicationId
AND ReceivableDetails.IsActive=1
UPDATE Receivables
SET TotalBookBalance_Amount = ReceivableDetails.EffectiveBookBalance_Amount,
UpdatedById = @CurrentUserId,
UpdatedTime = @CurrentTime
FROM Receivables
INNER JOIN ReceivableDetails
ON Receivables.id = ReceivableDetails.receivableId
WHERE Receivables.EntityId = @ContractId
AND Receivables.DueDate = @DueDateToUpdate
AND Receivables.IsActive=1
AND ReceivableDetails.IsActive=1
END

UPDATE ReceivableDetails
	SET EffectiveBalance_Amount =
		CASE
			WHEN #PreviousReceiptAppliedDetails.TotalAmountApplied IS NOT NULL THEN Amount_Amount - #PreviousReceiptAppliedDetails.TotalAmountApplied
			ELSE EffectiveBalance_Amount + ReceiptApplicationReceivableDetails.PreviousAmountApplied_Amount
		END,
	Balance_Amount =
		CASE
			WHEN #PreviousReceiptAppliedDetails.TotalAmountApplied IS NOT NULL THEN Amount_Amount - #PreviousReceiptAppliedDetails.TotalAmountApplied
			ELSE Balance_Amount + ReceiptApplicationReceivableDetails.PreviousAmountApplied_Amount
	END,
	UpdatedById = @CurrentUserId,
	UpdatedTime = @CurrentTime,
	LeaseComponentBalance_Amount = 
		CASE
			WHEN #PreviousReceiptAppliedDetails.TotalLeaseComponentAmountApplied IS NOT NULL THEN LeaseComponentAmount_Amount - #PreviousReceiptAppliedDetails.TotalLeaseComponentAmountApplied
			ELSE LeaseComponentBalance_Amount + ReceiptApplicationReceivableDetails.PrevLeaseComponentAmountApplied_Amount
		END
FROM ReceivableDetails
INNER JOIN ReceiptApplicationReceivableDetails
	ON ReceivableDetails.Id = ReceiptApplicationReceivableDetails.ReceivableDetailId
LEFT JOIN #PreviousReceiptAppliedDetails
	ON ReceivableDetails.Id = #PreviousReceiptAppliedDetails.ReceivableDetailId
WHERE ReceiptApplicationReceivableDetails.ReceiptApplicationId = @ApplicationId
	AND ReceivableDetails.IsActive=1

UPDATE ReceivableDetails
SET EffectiveBookBalance_Amount =
CASE
WHEN #PreviousReceiptAppliedDetails.TotalBookAmountApplied IS NOT NULL THEN Amount_Amount - #PreviousReceiptAppliedDetails.TotalBookAmountApplied
ELSE EffectiveBookBalance_Amount + ReceiptApplicationReceivableDetails.PreviousBookAmountApplied_Amount
END,
UpdatedById = @CurrentUserId,
UpdatedTime = @CurrentTime
FROM ReceivableDetails
INNER JOIN ReceiptApplicationReceivableDetails
ON ReceivableDetails.Id = ReceiptApplicationReceivableDetails.ReceivableDetailId
LEFT JOIN #PreviousReceiptAppliedDetails
ON ReceiptApplicationReceivableDetails.ReceivableDetailId = #PreviousReceiptAppliedDetails.ReceivableDetailId
WHERE ReceiptApplicationReceivableDetails.ReceiptApplicationId = @ApplicationId
AND ReceivableDetails.IsActive=1
AND ReceivableDetails.Id NOT IN (SELECT
receivableDetailId
FROM #MaxRecDetailIdToExclude)
UPDATE Receivables
SET Receivables.TotalBookBalance_Amount = ReceivableDetails.EffectiveBookBalance_Amount,
TotalBalance_Amount = Balance_Amount,
TotalEffectiveBalance_Amount = EffectiveBalance_Amount,
UpdatedById = @CurrentUserId,
UpdatedTime = @CurrentTime
FROM ReceiptApplicationReceivableDetails
INNER JOIN ReceivableDetails
ON ReceiptApplicationReceivableDetails.ReceivableDetailId = ReceivableDetails.Id
INNER JOIN Receivables
ON ReceivableDetails.ReceivableId = Receivables.Id
INNER JOIN ReceiptApplications
ON ReceiptApplications.Id = ReceiptApplicationReceivableDetails.ReceiptApplicationId
WHERE ReceiptApplications.ReceiptId = @ReceiptId
AND ReceiptApplications.Id = @ApplicationId
AND Receivables.IsActive=1
AND ReceivableDetails.IsActive=1
UPDATE ReceivableInvoiceDetails
SET Balance_Amount = ReceivableDetails.Balance_Amount,
EffectiveBalance_Amount = ReceivableDetails.EffectiveBalance_Amount,
UpdatedById = @CurrentUserId,
UpdatedTime = @CurrentTime
FROM ReceivableInvoiceDetails
INNER JOIN ReceivableDetails
ON ReceivableInvoiceDetails.ReceivableDetailId = ReceivableDetails.Id
INNER JOIN ReceiptApplicationReceivableDetails
ON ReceivableDetails.Id = ReceiptApplicationReceivableDetails.ReceivableDetailId
INNER JOIN ReceiptApplications
ON ReceiptApplications.Id = ReceiptApplicationReceivableDetails.ReceiptApplicationId
WHERE ReceiptApplications.ReceiptId = @ReceiptId
AND ReceiptApplications.Id = @ApplicationId
AND ReceivableInvoiceDetails.IsActive = 1
AND ReceiptApplicationReceivableDetails.IsReApplication = 0
UPDATE ReceivableInvoices
SET EffectiveBalance_Amount = InvoiceDetails.EffectiveBalance_Amount,
EffectiveBalance_Currency = InvoiceDetails.Currency,
WithHoldingTaxBalance_Amount = InvoiceDetails.WithHoldingTaxBalance,
WithHoldingTaxBalance_Currency = InvoiceDetails.Currency,
Balance_Amount = InvoiceDetails.Balance_Amount,
Balance_Currency = InvoiceDetails.Currency,
UpdatedById = @CurrentUserId,
UpdatedTime = @CurrentTime
OUTPUT INSERTED.ID AS ReceivableInvoiceId INTO #UpdateReceivableInvoice
FROM 
	(SELECT
	SUM(ReceivableInvoiceDetails.EffectiveBalance_Amount) AS EffectiveBalance_Amount,
	SUM(ReceivableInvoiceDetails.Balance_Amount) AS Balance_Amount,
	SUM(ISNULL(ReceivableDetailsWithholdingTaxDetails.Balance_Amount,0)) AS WithHoldingTaxBalance,
	ReceivableInvoices.Id AS ReceivableInvoiceID,
	ReceivableInvoiceDetails.Balance_Currency AS Currency
	FROM ReceivableInvoices
	INNER JOIN ReceivableInvoiceDetails
	ON ReceivableInvoices.Id = ReceivableInvoiceDetails.ReceivableInvoiceId
	LEFT JOIN ReceiptApplicationReceivableDetails
	ON ReceivableInvoiceDetails.ReceivableDetailId = ReceiptApplicationReceivableDetails.ReceivableDetailId
	LEFT JOIN ReceiptApplications
	ON ReceiptApplications.Id = ReceiptApplicationReceivableDetails.ReceiptApplicationId
	LEFT JOIN ReceivableDetailsWithholdingTaxDetails
	ON ReceivableInvoiceDetails.ReceivableDetailId = ReceivableDetailsWithholdingTaxDetails.ReceivableDetailId AND ReceivableDetailsWithholdingTaxDetails.IsActive=1
	WHERE (ReceiptApplications.ReceiptId IS NULL OR ReceiptApplications.ReceiptId = @ReceiptId)
	AND (ReceiptApplications.Id IS NULL OR ReceiptApplications.Id = @ApplicationId)
	AND ReceivableInvoices.IsActive = 1
	AND ReceivableInvoices.IsDummy = 0
	AND ReceivableInvoiceDetails.IsActive = 1
	AND (ReceiptApplicationReceivableDetails.IsReApplication IS NULL OR ReceiptApplicationReceivableDetails.IsReApplication = 0)
	GROUP BY ReceivableInvoices.Id,
	ReceivableInvoiceDetails.Balance_Currency) 
AS InvoiceDetails
WHERE ReceivableInvoices.id = InvoiceDetails.ReceivableInvoiceID
UPDATE ReceiptApplicationReceivableDetails
	SET ReceivedTowardsInterest_Amount = 0.00
WHERE ReceiptApplicationId = @ApplicationId
	AND IsActive = 1
END
ELSE
BEGIN
UPDATE ReceiptApplicationReceivableDetails
SET IsGLPosted = Receivables.IsGLPosted,
UpdatedById = @CurrentUserId,
UpdatedTime = @CurrentTime
FROM ReceiptApplicationReceivableDetails
JOIN ReceivableDetails
ON ReceiptApplicationReceivableDetails.ReceivableDetailId = ReceivableDetails.Id
JOIN Receivables
ON ReceivableDetails.ReceivableId = Receivables.Id
WHERE ReceiptApplicationReceivableDetails.ReceiptApplicationId = @ApplicationId
AND ReceiptApplicationReceivableDetails.IsActive = 1

UPDATE ReceiptApplicationReceivableDetails
SET AmountApplied_Amount = 0.0,
TaxApplied_Amount = 0.0,
BookAmountApplied_Amount = 0.0,
LeaseComponentAmountApplied_Amount = 0.0,
UpdatedById = @CurrentUserId,
UpdatedTime = @CurrentTime
FROM ReceiptApplicationReceivableDetails
WHERE ReceiptApplicationReceivableDetails.IsActive = 0
AND ReceiptApplicationReceivableDetails.ReceiptApplicationId = @ApplicationId;
UPDATE ReceivableDetails
SET Balance_Amount =
CASE
WHEN @UpdateBalance = 1 THEN Balance_Amount - ReceiptApplicationReceivableDetails.AmountApplied_Amount
ELSE ReceivableDetails.Balance_Amount
END,
EffectiveBalance_Amount = EffectiveBalance_Amount - (ReceiptApplicationReceivableDetails.AmountApplied_Amount - ISNULL(PreviousAmountApplied_Amount, 0.0)),
EffectiveBookBalance_Amount = EffectiveBookBalance_Amount - (ReceiptApplicationReceivableDetails.BookAmountApplied_Amount - ISNULL(PreviousBookAmountApplied_Amount, 0.0)),
UpdatedById = @CurrentUserId,
UpdatedTime = @CurrentTime,
LeaseComponentBalance_Amount =
									CASE
									  WHEN @UpdateBalance = 1 THEN LeaseComponentBalance_Amount - ReceiptApplicationReceivableDetails.LeaseComponentAmountApplied_Amount
									  ELSE ReceivableDetails.LeaseComponentBalance_Amount
									END
FROM ReceivableDetails
INNER JOIN ReceiptApplicationReceivableDetails
ON ReceivableDetails.Id = ReceiptApplicationReceivableDetails.ReceivableDetailId
INNER JOIN ReceiptApplications
ON ReceiptApplications.Id = ReceiptApplicationReceivableDetails.ReceiptApplicationId
WHERE ReceiptApplications.ReceiptId = @ReceiptId
AND ReceiptApplications.Id = @ApplicationId
AND ReceiptApplicationReceivableDetails.IsReApplication = 0

UPDATE ReceivableDetailsWithholdingTaxDetails
SET Balance_Amount =
CASE
WHEN @UpdateBalance = 1 THEN ReceivableDetailsWithholdingTaxDetails.Balance_Amount - AdjustedWithholdingTax_Amount
ELSE ReceivableDetailsWithholdingTaxDetails.Balance_Amount
END,
EffectiveBalance_Amount = ReceivableDetailsWithholdingTaxDetails.EffectiveBalance_Amount - (AdjustedWithholdingTax_Amount - ISNULL(PreviousAdjustedWithHoldingTax_Amount, 0.0)),
UpdatedById = @CurrentUserId,
UpdatedTime = @CurrentTime
FROM ReceivableDetailsWithholdingTaxDetails 
INNER JOIN ReceivableDetails
ON ReceivableDetailsWithholdingTaxDetails.ReceivableDetailId = ReceivableDetails.Id
INNER JOIN ReceiptApplicationReceivableDetails
ON ReceivableDetails.Id = ReceiptApplicationReceivableDetails.ReceivableDetailId
INNER JOIN ReceiptApplications
ON ReceiptApplications.Id = ReceiptApplicationReceivableDetails.ReceiptApplicationId
WHERE ReceiptApplications.ReceiptId = @ReceiptId
AND ReceiptApplications.Id = @ApplicationId
AND ReceiptApplicationReceivableDetails.IsReApplication = 0

UPDATE ReceivableInvoiceDetails
SET Balance_Amount =
CASE
WHEN @UpdateBalance = 1 THEN ReceivableDetails.Balance_Amount
ELSE ReceivableInvoiceDetails.Balance_Amount
END,
EffectiveBalance_Amount = ReceivableDetails.EffectiveBalance_Amount,
UpdatedById = @CurrentUserId,
UpdatedTime = @CurrentTime
FROM ReceivableInvoiceDetails
INNER JOIN ReceivableDetails
ON ReceivableInvoiceDetails.ReceivableDetailId = ReceivableDetails.Id
INNER JOIN ReceiptApplicationReceivableDetails
ON ReceivableDetails.Id = ReceiptApplicationReceivableDetails.ReceivableDetailId
INNER JOIN ReceiptApplications
ON ReceiptApplications.Id = ReceiptApplicationReceivableDetails.ReceiptApplicationId
WHERE ReceiptApplications.ReceiptId = @ReceiptId
AND ReceiptApplications.Id = @ApplicationId
AND ReceivableInvoiceDetails.IsActive = 1
AND ReceiptApplicationReceivableDetails.IsReApplication = 0

UPDATE ReceiptApplicationReceivableDetails
SET PreviousAmountApplied_Amount = ReceiptApplicationReceivableDetails.AmountApplied_Amount,
PreviousAmountApplied_Currency = ReceiptApplicationReceivableDetails.AmountApplied_Currency,
PreviousBookAmountApplied_Amount = ReceiptApplicationReceivableDetails.BookAmountApplied_Amount,
PreviousBookAmountApplied_Currency = ReceiptApplicationReceivableDetails.BookAmountApplied_Currency,
PrevLeaseComponentAmountApplied_Amount = ReceiptApplicationReceivableDetails.LeaseComponentAmountApplied_Amount,
PrevLeaseComponentAmountApplied_Currency = ReceiptApplicationReceivableDetails.LeaseComponentAmountApplied_Currency,
PreviousAdjustedWithHoldingTax_Amount = ReceiptApplicationReceivableDetails.AdjustedWithholdingTax_Amount,
UpdatedById = @CurrentUserId,
UpdatedTime = @CurrentTime
FROM ReceiptApplicationReceivableDetails
INNER JOIN ReceiptApplications
ON ReceiptApplications.Id = ReceiptApplicationReceivableDetails.ReceiptApplicationId
WHERE ReceiptApplications.ReceiptId = @ReceiptId
AND ReceiptApplications.Id = @ApplicationId
AND ReceiptApplicationReceivableDetails.IsReApplication = 0;

UPDATE ReceiptApplicationReceivableGroups
SET PreviousAmountApplied_Amount = ReceiptApplicationReceivableGroups.AmountApplied_Amount,
PreviousAmountApplied_Currency = ReceiptApplicationReceivableGroups.AmountApplied_Currency,
PreviousBookAmountApplied_Amount = ReceiptApplicationReceivableGroups.BookAmountApplied_Amount,
PreviousBookAmountApplied_Currency = ReceiptApplicationReceivableGroups.BookAmountApplied_Currency,
PreviousAdjustedWithHoldingTax_Amount = ReceiptApplicationReceivableGroups.PreviousAdjustedWithHoldingTax_Amount,
UpdatedById = @CurrentUserId,
UpdatedTime = @CurrentTime
FROM ReceiptApplicationReceivableGroups
INNER JOIN ReceiptApplications
ON ReceiptApplications.Id = ReceiptApplicationReceivableGroups.ReceiptApplicationId
WHERE ReceiptApplications.ReceiptId = @ReceiptId
AND ReceiptApplications.Id = @ApplicationId

UPDATE Receivables
SET Receivables.TotalBookBalance_Amount =
CASE
WHEN @UpdateBalance = 1 THEN Receivables.TotalBookBalance_Amount - ReceiptApplicationReceivableDetails.BookAmountApplied_Amount
ELSE Receivables.TotalBookBalance_Amount
END,
Receivables.TotalBookBalance_Currency =
CASE
WHEN @UpdateBalance = 1 THEN ReceiptApplicationReceivableDetails.BookAmountApplied_Currency
ELSE Receivables.TotalBookBalance_Currency
END,
TotalBalance_Amount =
CASE
WHEN @UpdateBalance = 1 THEN Balance_Amount
ELSE TotalBalance_Amount
END,
TotalEffectiveBalance_Amount = EffectiveBalance_Amount,
UpdatedById = @CurrentUserId,
UpdatedTime = @CurrentTime
FROM ReceiptApplicationReceivableDetails
INNER JOIN ReceivableDetails
ON ReceiptApplicationReceivableDetails.ReceivableDetailId = ReceivableDetails.Id
INNER JOIN Receivables
ON ReceivableDetails.ReceivableId = Receivables.Id
INNER JOIN ReceiptApplications
ON ReceiptApplications.Id = ReceiptApplicationReceivableDetails.ReceiptApplicationId
WHERE ReceiptApplications.ReceiptId = @ReceiptId
AND ReceiptApplications.Id = @ApplicationId
AND ReceivableDetails.IsActive=1
AND Receivables.IsActive=1

UPDATE ReceivableWithholdingTaxDetails
SET Balance_Amount =
CASE
WHEN @UpdateBalance = 1 THEN ReceivableDetailsWithholdingTaxDetails.Balance_Amount
ELSE ReceivableWithholdingTaxDetails.Balance_Amount
END,
EffectiveBalance_Amount = ReceivableDetailsWithholdingTaxDetails.EffectiveBalance_Amount,
UpdatedById = @CurrentUserId,
UpdatedTime = @CurrentTime
FROM ReceiptApplicationReceivableDetails
INNER JOIN ReceivableDetails
ON ReceiptApplicationReceivableDetails.ReceivableDetailId = ReceivableDetails.Id
INNER JOIN Receivables
ON ReceivableDetails.ReceivableId = Receivables.Id
INNER JOIN ReceivableWithholdingTaxDetails
ON ReceivableWithholdingTaxDetails.ReceivableId = Receivables.Id
INNER JOIN ReceivableDetailsWithholdingTaxDetails
ON ReceivableDetailsWithholdingTaxDetails.ReceivableWithholdingTaxDetailId = ReceivableWithholdingTaxDetails.Id
INNER JOIN ReceiptApplications
ON ReceiptApplications.Id = ReceiptApplicationReceivableDetails.ReceiptApplicationId
WHERE ReceiptApplications.ReceiptId = @ReceiptId
AND ReceiptApplications.Id = @ApplicationId
AND ReceivableDetails.IsActive=1
AND Receivables.IsActive=1

UPDATE ReceivableInvoices
SET EffectiveBalance_Amount = InvoiceDetails.EffectiveBalance_Amount,
EffectiveBalance_Currency = InvoiceDetails.Currency,
Balance_Amount =
CASE
WHEN @UpdateBalance = 1 THEN InvoiceDetails.Balance_Amount
ELSE ReceivableInvoices.Balance_Amount
END,
Balance_Currency =
CASE
WHEN @UpdateBalance = 1 THEN InvoiceDetails.Currency
ELSE ReceivableInvoices.Balance_Currency
END,
WithHoldingTaxBalance_Amount =
CASE
WHEN @UpdateBalance = 1 THEN InvoiceDetails.WHTBalanceAmount
ELSE ReceivableInvoices.WithHoldingTaxBalance_Amount
END,
UpdatedById = @CurrentUserId,
UpdatedTime = @CurrentTime
OUTPUT INSERTED.ID AS ReceivableInvoiceId INTO #UpdateReceivableInvoice
FROM (SELECT
SUM(ReceivableInvoiceDetails.EffectiveBalance_Amount) AS EffectiveBalance_Amount,
SUM(ReceivableInvoiceDetails.Balance_Amount) AS Balance_Amount,
SUM(ReceivableDetailsWithholdingTaxDetails.Balance_Amount) AS WHTBalanceAmount,
SUM(ReceivableDetailsWithholdingTaxDetails.EffectiveBalance_Amount) AS WHTEffectiveBalanceAmount,
ReceivableInvoices.Id AS ReceivableInvoiceID,
ReceivableInvoiceDetails.Balance_Currency AS Currency
FROM ReceivableInvoices
INNER JOIN ReceivableInvoiceDetails
ON ReceivableInvoices.Id = ReceivableInvoiceDetails.ReceivableInvoiceId
INNER JOIN ReceivableDetailsWithholdingTaxDetails
ON ReceivableInvoiceDetails.ReceivableDetailId = ReceivableDetailsWithholdingTaxDetails.ReceivableDetailId
LEFT JOIN ReceiptApplicationReceivableDetails
ON ReceivableInvoiceDetails.ReceivableDetailId = ReceiptApplicationReceivableDetails.ReceivableDetailId
LEFT JOIN ReceiptApplications
ON ReceiptApplications.Id = ReceiptApplicationReceivableDetails.ReceiptApplicationId
WHERE (ReceiptApplications.ReceiptId IS NULL OR ReceiptApplications.ReceiptId = @ReceiptId)
AND (ReceiptApplications.Id IS NULL OR ReceiptApplications.Id = @ApplicationId)
AND ReceivableInvoices.IsActive = 1
AND ReceivableInvoiceS.IsDummy = 0
AND ReceivableInvoiceDetails.IsActive = 1
AND (ReceiptApplicationReceivableDetails.IsReApplication IS NULL OR ReceiptApplicationReceivableDetails.IsReApplication = 0)
GROUP BY ReceivableInvoices.Id,
ReceivableInvoiceDetails.Balance_Currency) AS InvoiceDetails
WHERE ReceivableInvoices.id = InvoiceDetails.ReceivableInvoiceID

UPDATE ReceiptApplicationReceivableDetails
SET AmountApplied_Amount = 0.0,
BookAmountApplied_Amount = 0.0,
LeaseComponentAmountApplied_Amount = 0.0,
UpdatedById = @CurrentUserId,
UpdatedTime = @CurrentTime
FROM ReceiptApplicationReceivableDetails
WHERE ReceiptApplicationReceivableDetails.IsActive = 0
AND ReceiptApplicationReceivableDetails.ReceiptApplicationId = @ApplicationId;
END

UPDATE ReceiptApplicationReceivableDetails
SET ReceivableInvoiceId =
CASE
WHEN @IsReversal = 0 THEN ReceivableInvoiceDetails.ReceivableInvoiceId
ELSE ReceiptApplicationReceivableDetails.ReceivableInvoiceId
END,
UpdatedById = @CurrentUserId,
UpdatedTime = @CurrentTime
FROM ReceiptApplicationReceivableDetails
INNER JOIN ReceivableInvoiceDetails
ON ReceivableInvoiceDetails.ReceivableDetailId = ReceiptApplicationReceivableDetails.ReceivableDetailId
WHERE
ReceiptApplicationReceivableDetails.ReceiptApplicationId = @ApplicationId
AND ReceiptApplicationReceivableDetails.IsReApplication = 0;
IF (@UpdateBalance = 1 OR @IsReversal = 1)
BEGIN
SELECT
PaymentScheduleId AS Id,
TotalBookBalance_Amount - TotalBalance_Amount AS InterestAmountApplied,
LoanPaymentSchedules.StartDate,
EndDate,
LoanPaymentSchedules.LoanFinanceId,
ReceivableTypes.Name AS TypeName
INTO #PaymentscheduleDetails
FROM Receivables
INNER JOIN ReceivableDetails
ON ReceivableDetails.ReceivableId = Receivables.Id
INNER JOIN ReceivableCodes
ON Receivables.ReceivableCodeId = ReceivableCodes.Id
INNER JOIN ReceivableTypes
ON ReceivableCodes.ReceivableTypeId = ReceivableTypes.Id
INNER JOIN LoanPaymentSchedules
ON Receivables.PaymentScheduleId = LoanPaymentSchedules.Id
WHERE ReceivableTypes.Name = 'LoanInterest'
AND Receivables.EntityId = @ContractId
AND Receivables.IsActive = 1
AND ReceivableDetails.IsActive = 1
AND Receivables.FunderId IS NULL
ORDER BY PaymentScheduleId
SELECT
PaymentscheduleDetails1.Id,
SUM(PaymentscheduleDetails2.InterestAmountApplied) AS CumulativeInterestAmountApplied,
DATEADD(DAY, -1, PaymentscheduleDetails1.StartDate) AS StartDate,
PaymentscheduleDetails1.EndDate
AS EndDate,
PaymentscheduleDetails1.LoanFinanceId,
ROW_NUMBER() OVER (ORDER BY PaymentscheduleDetails1.StartDate) AS row
INTO #ValidPaymentscheduleDetails
FROM #PaymentscheduleDetails PaymentscheduleDetails1
INNER JOIN #PaymentscheduleDetails PaymentscheduleDetails2
ON PaymentscheduleDetails1.StartDate >= PaymentscheduleDetails2.StartDate
WHERE PaymentscheduleDetails1.InterestAmountApplied != 0
GROUP BY PaymentscheduleDetails1.Id,
PaymentscheduleDetails1.StartDate,
PaymentscheduleDetails1.EndDate,
PaymentscheduleDetails1.LoanFinanceId
ORDER BY PaymentscheduleDetails1.Id
DECLARE @count int
DECLARE @index int = 1
DECLARE @isAdvance bit
SELECT
@count = COUNT(Id)
FROM #ValidPaymentscheduleDetails
--print @count
SELECT
@isAdvance = IsAdvance
FROM LoanFinances
WHERE IsCurrent = 1
AND ContractId = @ContractId
UPDATE LoanIncomeSchedules
SET LoanIncomeSchedules.CumulativeInterestAppliedToPrincipal_Amount = 0.00,
UpdatedById = @CurrentUserId,
UpdatedTime = @CurrentTime
FROM LoanIncomeSchedules
INNER JOIN LoanFinances
ON LoanIncomeSchedules.LoanFinanceId = LoanFinances.Id
INNER JOIN Contracts
ON LoanFinances.ContractId = contracts.Id
WHERE Contracts.Id = @ContractId
AND LoanFinances.IsCurrent = 1
AND (LoanIncomeSchedules.IsAccounting != 0
OR LoanIncomeSchedules.IsSchedule != 0)
WHILE (@index <= @count)
BEGIN
UPDATE LoanIncomeSchedules
SET LoanIncomeSchedules.CumulativeInterestAppliedToPrincipal_Amount = t.CumulativeInterestAmountApplied,
UpdatedById = @CurrentUserId,
UpdatedTime = @CurrentTime
FROM (SELECT DISTINCT
LoanIncomeSchedules.Id,
IncomeDate,
CumulativeInterestAppliedToPrincipal_Amount,
#ValidPaymentscheduleDetails.CumulativeInterestAmountApplied
FROM LoanIncomeSchedules
INNER JOIN #ValidPaymentscheduleDetails
ON LoanIncomeSchedules.LoanFinanceId = #ValidPaymentscheduleDetails.loanfinanceid
WHERE ((@isAdvance = 0
AND LoanIncomeSchedules.IncomeDate >= #ValidPaymentscheduleDetails.EndDate)
OR (@isAdvance = 1
AND LoanIncomeSchedules.IncomeDate >= #ValidPaymentscheduleDetails.Startdate))
AND #ValidPaymentscheduleDetails.row = @index
AND (LoanIncomeSchedules.IsAccounting != 0
OR LoanIncomeSchedules.IsSchedule != 0)
AND LoanIncomeSchedules.IsLessorOwned = 1) AS t
WHERE t.Id = LoanIncomeSchedules.Id
SET @index = @index + 1
END
DROP TABLE #PaymentscheduleDetails
DROP TABLE #ValidPaymentscheduleDetails
END
IF @UpdateBalance = 1
AND @IsReversal = 0
BEGIN
SELECT
@ReceiptId AS ReceiptId,
ReceiptApplicationReceivableDetails.ReceivableInvoiceId AS ReceivableInvoiceId,
SUM(ReceiptApplicationReceivableDetails.AmountApplied_Amount) AS AmountApplied,
SUM(ReceiptApplicationReceivableDetails.TaxApplied_Amount) AS TaxApplied,
ReceiptApplicationReceivableDetails.AmountApplied_Currency AS Currency
INTO #TempReceiptApplicationReceivableDetail
FROM ReceiptApplicationReceivableDetails
INNER JOIN ReceiptApplications
ON ReceiptApplications.Id = ReceiptApplicationReceivableDetails.ReceiptApplicationId
WHERE ReceiptApplications.ReceiptId = @ReceiptId
AND ReceiptApplicationReceivableDetails.ReceivableInvoiceId IS NOT NULL
GROUP BY ReceiptApplicationReceivableDetails.ReceivableInvoiceId,
ReceiptApplicationReceivableDetails.AmountApplied_Currency
INSERT INTO ReceivableInvoiceReceiptDetails (ReceiptId, ReceivedDate, IsActive, ReceivableInvoiceId,
AmountApplied_Amount, AmountApplied_Currency, TaxApplied_Amount, TaxApplied_Currency, CreatedById, CreatedTime)
SELECT
@ReceiptId AS ReceiptId,
@ReceivedDate AS ReceivedDate,
1 AS IsActive,
#TempReceiptApplicationReceivableDetail.ReceivableInvoiceId AS ReceivableInvoiceId,
#TempReceiptApplicationReceivableDetail.AmountApplied AS AmountApplied_Amount,
#TempReceiptApplicationReceivableDetail.Currency AS AmountApplied_Currency,
#TempReceiptApplicationReceivableDetail.TaxApplied AS TaxApplied_Amount,
#TempReceiptApplicationReceivableDetail.Currency AS TaxApplied_Currency,
@CurrentUserId AS CreatedById,
@CurrentTime AS CreatedTime
FROM #TempReceiptApplicationReceivableDetail
UPDATE ReceivableInvoices
SET LastReceivedDate = LastReceivedDateDetails.LastReceivedDate,
UpdatedById = @CurrentUserId,
UpdatedTime = @CurrentTime
FROM ReceivableInvoices
INNER JOIN (SELECT
ReceivableInvoiceReceiptDetails.ReceivableInvoiceId AS ReceivableInvoiceId,
MAX(ReceivableInvoiceReceiptDetails.ReceivedDate) AS LastReceivedDate
FROM ReceivableInvoiceReceiptDetails
INNER JOIN #TempReceiptApplicationReceivableDetail
ON #TempReceiptApplicationReceivableDetail.ReceivableInvoiceId = ReceivableInvoiceReceiptDetails.ReceivableInvoiceId
WHERE ReceivableInvoiceReceiptDetails.IsActive = 1
AND (ReceivableInvoiceReceiptDetails.AmountApplied_Amount != 0
OR ReceivableInvoiceReceiptDetails.TaxApplied_Amount != 0)
GROUP BY ReceivableInvoiceReceiptDetails.ReceivableInvoiceId) AS LastReceivedDateDetails
ON LastReceivedDateDetails.ReceivableInvoiceId = ReceivableInvoices.Id
DROP TABLE #TempReceiptApplicationReceivableDetail
END
DROP TABLE #MaxRecDetailIdToExclude

	SELECT DISTINCT StatementInvoiceId 
	   INTO #StatementInvoicesOfReceivableInvoices
	   FROM #UpdateReceivableInvoice RI
	   INNER JOIN ReceivableInvoiceStatementAssociations RISA ON RI.ReceivableInvoiceId = RISA.ReceivableInvoiceId
	   WHERE RI.ReceivableInvoiceId IS NOT NULL

	   IF EXISTS(SELECT TOP 1 * FROM #StatementInvoicesOfReceivableInvoices)
	   BEGIN
	   SELECT 
			SRI.StatementInvoiceId,
			Balance_Amount = ISNULL(SUM(RI.Balance_Amount), 0),
			TaxBalance_Amount = ISNULL(SUM(TaxBalance_Amount),0),	
			EffectiveBalance_Amount = ISNULL(SUM(RI.EffectiveBalance_Amount), 0),
			EffectiveTaxBalance_Amount = ISNULL(SUM(EffectiveTaxBalance_Amount),0),
			WithHoldingTaxBalance_Amount = ISNULL(SUM(WithHoldingTaxBalance_Amount),0)
		INTO #StatementInvoicesUpdateAmount
		FROM #StatementInvoicesOfReceivableInvoices SRI 
		INNER JOIN ReceivableInvoiceStatementAssociations RSI ON SRI.StatementInvoiceId = RSI.StatementInvoiceID
		INNER JOIN ReceivableInvoices RI ON RSI.ReceivableInvoiceId = RI.Id AND RI.IsActive =1
		GROUP BY SRI.StatementInvoiceId

		UPDATE RI
		SET 
		   Balance_Amount =  SRI.Balance_Amount,
		   TaxBalance_Amount = SRI.TaxBalance_Amount,
		   EffectiveBalance_Amount = SRI.EffectiveBalance_Amount,
		   EffectiveTaxBalance_Amount = SRI.EffectiveTaxBalance_Amount,
		   WithHoldingTaxBalance_Amount = SRI.WithHoldingTaxBalance_Amount,
		   UpdatedById = @CurrentUserId, 
		   UpdatedTime = @CurrentTime
		FROM ReceivableInvoices RI
		INNER JOIN #StatementInvoicesUpdateAmount SRI ON RI.Id = SRI.StatementInvoiceId
		END

		DROP TABLE #UpdateReceivableInvoice
END

GO
