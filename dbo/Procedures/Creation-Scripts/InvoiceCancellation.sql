SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[InvoiceCancellation]
(
@InvoiceIds InvoiceIds READONLY,
@BilledStatus NVARCHAR(30),
@CancelledById BIGINT,
@UpdatedBy VARCHAR(30),
@UpdatedTime DATETIMEOFFSET,
@jobStepInstanceId BIGINT = NULL ,
@CancelAllAssociatedInvoice   BIT =0
)
AS
BEGIN

BEGIN TRY
BEGIN TRANSACTION
SET NOCOUNT ON;

CREATE TABLE #CashPostedInvoices(InvoiceId BIGINT,IsStatementInvoice bit);
CREATE TABLE #LateFeeInvoices(InvoiceId BIGINT);
CREATE TABLE #Invoices(InvoiceId BIGINT,LastStatementGeneratedDueDate DATETIME, DueDate DATETIME ,IsStatementInvoice BIT );
CREATE TABLE #InvoicesWithoutCashpostedInvoices(InvoiceId BIGINT);
CREATE TABLE #InvoicesToCancel(InvoiceId Bigint);
CREATE TABLE #InvoicesToCancelTemp(InvoiceId Bigint);
CREATE TABLE #AlreadyCancelledInvoices(InvoiceId BIGINT);
CREATE TABLE #InvoiceAsPartOfOneTimeACH(InvoiceId BIGINT,OnetimeACHId BIGINT);
CREATE TABLE #AllAssociatedStatementInvoices(ReceivableInvoiceId BIGINT,StatementInvoiceId BIGINT, LastStatementGeneratedDueDate DATETIME,DueDate DATE,IsStatementInvoice BIT, IsCurrentInvoice BIT )
CREATE TABLE #StatementInvoiceAssociatedReceivableInvoices(ReceivableInvoiceId BIGINT,StatementInvoiceId BIGINT, LastStatementGeneratedDueDate DATETIME,DueDate DATE,IsStatementInvoice BIT )
CREATE TABLE #StatementInvoiceAssociatedReceivableInvoicesForUpdating(ReceivableInvoiceId BIGINT,StatementInvoiceId BIGINT, LastStatementGeneratedDueDate DATETIME,DueDate DATE,IsStatementInvoice BIT)

SELECT
InvoiceId AS InvoiceId,
IsStatementInvoice
INTO #InvoiceIds
FROM @InvoiceIds

INSERT INTO #AllAssociatedStatementInvoices
SELECT ReceivableInvoiceId, StatementInvoiceId, LastStatementGeneratedDueDate ,DueDate, ReceivableInvoices.IsStatementInvoice, ReceivableInvoiceStatementAssociations.IsCurrentInvoice
FROM #InvoiceIds inv
JOIN ReceivableInvoiceStatementAssociations ON inv.IsStatementInvoice = 1 AND inv.InvoiceId  = ReceivableInvoiceStatementAssociations.StatementInvoiceID
JOIN ReceivableInvoices ON ReceivableInvoiceStatementAssociations.ReceivableInvoiceID = ReceivableInvoices.Id
AND ReceivableInvoices.IsActive = 1

IF(@CancelAllAssociatedInvoice = 0)
INSERT INTO #StatementInvoiceAssociatedReceivableInvoices
SELECT ReceivableInvoiceId, StatementInvoiceId, LastStatementGeneratedDueDate ,DueDate, IsStatementInvoice
FROM #AllAssociatedStatementInvoices WHERE IsCurrentInvoice = 1

IF(@CancelAllAssociatedInvoice = 1)
	INSERT INTO #StatementInvoiceAssociatedReceivableInvoices
	SELECT ReceivableInvoiceId, StatementInvoiceId, LastStatementGeneratedDueDate ,DueDate, IsStatementInvoice
	FROM #AllAssociatedStatementInvoices

INSERT INTO #Invoices
SELECT inv.InvoiceId, LastStatementGeneratedDueDate,DueDate, inv.IsStatementInvoice  FROM #InvoiceIds inv
JOIN ReceivableInvoices ON inv.InvoiceId = ReceivableInvoices.Id
AND ReceivableInvoices.IsActive = 1

UNION

SELECT ReceivableInvoiceId, LastStatementGeneratedDueDate,DueDate, IsStatementInvoice  FROM #StatementInvoiceAssociatedReceivableInvoices

--To Reduce Balance of Statement Invoice if any associated invoice is cancelled.
SELECT ReceivableInvoiceStatementAssociations.StatementInvoiceId AS StatementInvoiceId
INTO #StatementInvoicesOfReceivableInvoices
FROM #Invoices inv
INNER JOIN ReceivableInvoiceStatementAssociations ON inv.IsStatementInvoice = 0 AND inv.InvoiceId  = ReceivableInvoiceStatementAssociations.ReceivableInvoiceId
GROUP BY ReceivableInvoiceStatementAssociations.StatementInvoiceId

DELETE  SI
FROM #StatementInvoicesOfReceivableInvoices SI
INNER JOIN #Invoices Inv
ON Inv.InvoiceId = SI.StatementInvoiceId

/*this should not happen in business but if the user re-runs the same job again then system will
send the same invoice becoz the parameters are already stored in the DB*/
INSERT INTO #AlreadyCancelledInvoices
SELECT inv.InvoiceId FROM #InvoiceIds inv
JOIN ReceivableInvoices ON inv.InvoiceId = ReceivableInvoices.Id
AND ReceivableInvoices.IsActive = 0

IF ((SELECT COUNT(*) FROM #AlreadyCancelledInvoices) > 0 AND @jobStepInstanceId IS NOT NULL)
BEGIN
	DECLARE @AlreadyCancelledInvoices NVARCHAR(MAX)

	SELECT @AlreadyCancelledInvoices = COALESCE(@AlreadyCancelledInvoices + ',', '') +  CONVERT(VARCHAR(12),ri.Number)
	FROM dbo.ReceivableInvoices ri
	WHERE ri.Id IN (SELECT aci.InvoiceId from #AlreadyCancelledInvoices aci)
	ORDER BY ri.Number

	INSERT INTO dbo.JobStepInstanceLogs(Message,MessageType,CreatedById,CreatedTime,UpdatedById,UpdatedTime,JobStepInstanceId)
	VALUES (CONCAT('Invoice Number(s) {', @AlreadyCancelledInvoices ,'} cannot be cancelled because they are not active'),
	N'Error', @UpdatedBy, @UpdatedTime, NULL, NULL, @jobStepInstanceId)
END

--Cash posted Info for Receivable Invoices
INSERT INTO #CashPostedInvoices
	SELECT RI.Id , 0 FROM #Invoices I
		INNER JOIN ReceivableInvoices RI on I.InvoiceId = RI.Id
		INNER JOIN ReceivableInvoiceDetails RID on RI.Id = RID.ReceivableInvoiceId and RID.IsActive=1
		INNER JOIN ReceivableDetails RD on RID.ReceivableDetailId = RD.Id and RD.IsActive = 1
		INNER JOIN Receivables R on RD.Receivableid = R.Id and R.IsActive = 1
		where R.IsCollected=1
			AND (ABS(RID.InvoiceAmount_Amount) > ABS(RID.EffectiveBalance_Amount) 
				OR ABS(RID.InvoiceTaxAmount_Amount) > ABS(RID.EffectiveTaxBalance_Amount))
			AND I.IsStatementInvoice = 0
		GROUP BY RI.Id


IF(@CancelAllAssociatedInvoice = 1)
BEGIN
 --Cash posted Info for Statement Invoices
       INSERT INTO #CashPostedInvoices
		SELECT SI.StatementInvoiceId , 1 FROM #Invoices I
		INNER JOIN ReceivableInvoiceStatementAssociations SI ON I.InvoiceId = SI.StatementInvoiceId
		INNER JOIN ReceivableInvoices RI on SI.ReceivableInvoiceId = RI.Id
		INNER JOIN ReceivableInvoiceDetails RID on RI.Id = RID.ReceivableInvoiceId and RID.IsActive=1
		INNER JOIN ReceivableDetails RD on RID.ReceivableDetailId = RD.Id and RD.IsActive = 1
		INNER JOIN Receivables R on RD.Receivableid = R.Id and R.IsActive = 1
		where R.IsCollected=1
			AND (ABS(RID.InvoiceAmount_Amount) > ABS(RID.EffectiveBalance_Amount)
				OR ABS(RID.InvoiceTaxAmount_Amount) > ABS(RID.EffectiveTaxBalance_Amount))
			AND I.IsStatementInvoice = 1
		GROUP BY SI.StatementInvoiceId

	INSERT INTO #CashPostedInvoices
	SELECT statInv.ReceivableInvoiceId, 1 
	FROM #CashPostedInvoices inv
	INNER JOIN ReceivableInvoiceStatementAssociations statInv ON inv.InvoiceId = statInv.StatementInvoiceID
END

IF(@CancelAllAssociatedInvoice = 0)
BEGIN
 --Cash posted Info for Statement Invoices
        INSERT INTO #CashPostedInvoices
		SELECT SI.StatementInvoiceId, 1 FROM #Invoices I
		INNER JOIN ReceivableInvoiceStatementAssociations SI ON I.InvoiceId = SI.StatementInvoiceId AND SI.IsCurrentInvoice = 1
		INNER JOIN ReceivableInvoices RI on SI.ReceivableInvoiceId = RI.Id
		INNER JOIN ReceivableInvoiceDetails RID on RI.Id = RID.ReceivableInvoiceId and RID.IsActive=1
		INNER JOIN ReceivableDetails RD on RID.ReceivableDetailId = RD.Id and RD.IsActive = 1
		INNER JOIN Receivables R on RD.Receivableid = R.Id and R.IsActive = 1
		where R.IsCollected=1
			AND (ABS(RID.InvoiceAmount_Amount) > ABS(RID.EffectiveBalance_Amount)
				OR ABS(RID.InvoiceTaxAmount_Amount) > ABS(RID.EffectiveTaxBalance_Amount))
			AND I.IsStatementInvoice = 1
		GROUP BY SI.StatementInvoiceId


	;WITH CTE_CashPostedStatementInvoice as
	(
		SELECT InvoiceId
		,currentInvoiceId = statInv.ReceivableInvoiceId
		,ReceiptId =  RASI.Id 					
		FROM #CashPostedInvoices inv
		LEFT JOIN ReceivableInvoiceStatementAssociations statInv ON inv.InvoiceId = statInv.StatementInvoiceID AND statInv.IsCurrentInvoice = 1
		LEFT JOIN ReceiptApplicationStatementInvoices RASI ON inv.InvoiceId = RASI.StatementInvoiceId
		WHERE inv.IsStatementInvoice = 1
	)
	DELETE #CashPostedInvoices FROM #CashPostedInvoices 
	JOIN CTE_CashPostedStatementInvoice ON #CashPostedInvoices.InvoiceId = CTE_CashPostedStatementInvoice.InvoiceId 
	WHERE currentInvoiceId IS NULL AND ReceiptId IS NULL;
	
	INSERT INTO #CashPostedInvoices
	SELECT statInv.ReceivableInvoiceId, 1
	FROM #CashPostedInvoices inv
	INNER JOIN ReceivableInvoiceStatementAssociations statInv ON inv.InvoiceId = statInv.StatementInvoiceID AND statInv.IsCurrentInvoice = 1
END

;WITH CTE_CashPostedInvoice as
(
	SELECT InvoiceId,
	ROW_NUMBER() OVER(PARTITION BY  InvoiceId
	ORDER BY InvoiceId DESC) invoiceCount
	FROM #CashPostedInvoices
)
DELETE FROM CTE_CashPostedInvoice
WHERE invoiceCount > 1;

--Late fee Info for Receivable Invoices
INSERT INTO #LateFeeInvoices
	SELECT ri.Id FROM #Invoices i
	INNER JOIN dbo.LateFeeReceivables lfr ON lfr.ReceivableInvoiceId = i.InvoiceId
	INNER JOIN dbo.ReceivableInvoices ri ON lfr.ReceivableInvoiceId = ri.Id
	WHERE lfr.IsActive = 1 AND lfr.ReversedDate IS NULL
	AND i.IsStatementInvoice = 0

--Late fee Info for Statement Invoices
INSERT INTO #LateFeeInvoices
	SELECT sta.ReceivableInvoiceId FROM #Invoices i
	INNER JOIN dbo.ReceivableInvoiceStatementAssociations sta ON i.InvoiceId = sta.StatementInvoiceId
	INNER JOIN dbo.LateFeeReceivables lfr ON lfr.ReceivableInvoiceId = sta.ReceivableInvoiceId
	WHERE lfr.IsActive = 1 AND lfr.ReversedDate IS NULL
	AND i.IsStatementInvoice = 1

IF(@CancelAllAssociatedInvoice = 1)
BEGIN
	INSERT INTO #LateFeeInvoices
	SELECT statInv.StatementInvoiceId
	FROM #LateFeeInvoices inv
	INNER JOIN ReceivableInvoiceStatementAssociations statInv ON inv.InvoiceId = statInv.ReceivableInvoiceId
	
	INSERT INTO #LateFeeInvoices
	SELECT statInv.ReceivableInvoiceId
	FROM #LateFeeInvoices inv
	INNER JOIN ReceivableInvoiceStatementAssociations statInv ON inv.InvoiceId = statInv.StatementInvoiceID
END

IF(@CancelAllAssociatedInvoice = 0)
BEGIN
	INSERT INTO #LateFeeInvoices
	SELECT statInv.StatementInvoiceId
	FROM #LateFeeInvoices inv
	INNER JOIN ReceivableInvoiceStatementAssociations statInv ON inv.InvoiceId = statInv.ReceivableInvoiceId AND statInv.IsCurrentInvoice = 1
	
	INSERT INTO #LateFeeInvoices
	SELECT statInv.ReceivableInvoiceId
	FROM #LateFeeInvoices inv
	INNER JOIN ReceivableInvoiceStatementAssociations statInv ON inv.InvoiceId = statInv.StatementInvoiceID AND statInv.IsCurrentInvoice = 1
END

;WITH CTE_LateFeeInvoices as
(
	SELECT InvoiceId,
	ROW_NUMBER() OVER(PARTITION BY  InvoiceId
	ORDER BY InvoiceId DESC) invoiceCount
	FROM #LateFeeInvoices
)
DELETE FROM CTE_LateFeeInvoices
WHERE invoiceCount > 1;

--One Time ACH Info for Receivable Invoice
INSERT INTO #InvoiceAsPartOfOneTimeACH
	select ri.Id, otach.Id FROM #Invoices i
	INNER JOIN ReceivableInvoices ri ON i.InvoiceId = ri.Id
	INNER JOIN OneTimeACHInvoices oti ON ri.Id = oti.ReceivableInvoiceId
	INNER JOIN OneTimeACHes otach ON otach.Id = oti.OneTimeACHId
    WHERE oti.IsActive = 1 AND ri.IsActive = 1 
	AND otach.Status = 'Pending' OR otach.Status = 'FileGenerated'
	AND i.IsStatementInvoice = 0

--One Time ACH Info for Statement Invoice
INSERT INTO #InvoiceAsPartOfOneTimeACH
	select sta.ReceivableInvoiceId, otach.Id FROM #Invoices i
	INNER JOIN ReceivableInvoiceStatementAssociations sta ON i.InvoiceId = sta.StatementInvoiceId
	INNER JOIN OneTimeACHInvoices oti ON sta.ReceivableInvoiceId = oti.ReceivableInvoiceId
	INNER JOIN OneTimeACHes otach ON otach.Id = oti.OneTimeACHId
    WHERE oti.IsActive = 1 
	AND otach.Status = 'Pending' OR otach.Status = 'FileGenerated'
	AND i.IsStatementInvoice = 1

IF(@CancelAllAssociatedInvoice = 1)
BEGIN
	INSERT INTO #InvoiceAsPartOfOneTimeACH
	SELECT statInv.StatementInvoiceId, inv.OnetimeACHId
	FROM #InvoiceAsPartOfOneTimeACH inv
	INNER JOIN ReceivableInvoiceStatementAssociations statInv ON inv.InvoiceId = statInv.ReceivableInvoiceId
	
	INSERT INTO #InvoiceAsPartOfOneTimeACH
	SELECT statInv.ReceivableInvoiceId , inv.OnetimeACHId
	FROM #InvoiceAsPartOfOneTimeACH inv
	INNER JOIN ReceivableInvoiceStatementAssociations statInv ON inv.InvoiceId = statInv.StatementInvoiceID
END

IF(@CancelAllAssociatedInvoice = 0)
BEGIN
	INSERT INTO #InvoiceAsPartOfOneTimeACH
	SELECT statInv.StatementInvoiceId, inv.OnetimeACHId
	FROM #InvoiceAsPartOfOneTimeACH inv
	INNER JOIN ReceivableInvoiceStatementAssociations statInv ON inv.InvoiceId = statInv.ReceivableInvoiceId AND statInv.IsCurrentInvoice = 1
	
	INSERT INTO #InvoiceAsPartOfOneTimeACH
	SELECT statInv.ReceivableInvoiceId, inv.OnetimeACHId
	FROM #InvoiceAsPartOfOneTimeACH inv
	INNER JOIN ReceivableInvoiceStatementAssociations statInv ON inv.InvoiceId = statInv.StatementInvoiceID AND statInv.IsCurrentInvoice = 1
END

;WITH CTE_InvoiceAsPartOfOneTimeACH  as
(
	SELECT InvoiceId,
	ROW_NUMBER() OVER(PARTITION BY  InvoiceId
	ORDER BY InvoiceId DESC) invoiceCount
	FROM #InvoiceAsPartOfOneTimeACH
)
DELETE FROM CTE_InvoiceAsPartOfOneTimeACH
WHERE invoiceCount > 1;

INSERT INTO #InvoicesWithoutCashpostedInvoices
SELECT i.InvoiceId FROM #Invoices i
LEFT JOIN #CashPostedInvoices cpafi ON i.InvoiceId = cpafi.InvoiceId
LEFT JOIN #InvoiceAsPartOfOneTimeACH otachi ON i.InvoiceId = otachi.InvoiceId
WHERE cpafi.InvoiceId IS NULL AND otachi.InvoiceId IS NULL

INSERT INTO #InvoicesToCancelTemp
SELECT iwci.InvoiceId FROM #InvoicesWithoutCashpostedInvoices iwci
LEFT JOIN #LateFeeInvoices lfi ON iwci.InvoiceId = lfi.InvoiceId
WHERE lfi.InvoiceId IS NULL

INSERT INTO #InvoicesToCancel
SELECT DISTINCT itct.InvoiceId FROM #InvoicesToCancelTemp itct

INSERT INTO #StatementInvoiceAssociatedReceivableInvoicesForUpdating
SELECT ReceivableInvoiceId, StatementInvoiceId, LastStatementGeneratedDueDate ,DueDate, IsStatementInvoice
FROM #AllAssociatedStatementInvoices ASI
LEFT JOIN #InvoicesToCancel I ON ASI.ReceivableInvoiceId = I.InvoiceId
INNER JOIN #InvoicesToCancel SI ON SI.InvoiceId = ASI.StatementInvoiceId
WHERE I.InvoiceId IS  NULL

;WITH CTE_ReceivableInvoiceToUpdateLastGeneratedDueDate
AS
(
	SELECT stInv.ReceivableInvoiceId, Min(inv.DueDate)AS StateInvoiceMinDueDate, Max(inv.DueDate) StateInvoiceMaxDueDate
	FROM #StatementInvoiceAssociatedReceivableInvoicesForUpdating stInv
	JOIN #Invoices inv ON inv.InvoiceId = stInv.StatementInvoiceId AND stInv.LastStatementGeneratedDueDate IS NOT NULL
	JOIN #InvoicesToCancel inc ON inc.InvoiceId = inv.InvoiceId
	GROUP BY stInv.ReceivableInvoiceId
),
CTE_MinStatementInvoiceIdToUpdateLastGeneratedDueDate
AS
(
	SELECT invLGDD.ReceivableInvoiceId, Min(inv.StatementInvoiceId) AS MinStatementInvoiceId
	FROM CTE_ReceivableInvoiceToUpdateLastGeneratedDueDate invLGDD
	INNER JOIN #StatementInvoiceAssociatedReceivableInvoicesForUpdating inv ON invLGDD.ReceivableInvoiceId = inv.ReceivableInvoiceId
	WHERE invLGDD.StateInvoiceMaxDueDate >= inv.LastStatementGeneratedDueDate
	GROUP BY invLGDD.ReceivableInvoiceId
)
SELECT MSI.ReceivableInvoiceId, MAX(StatementInvoiceId) AS StatementInvoiceId
INTO #EligibileStatementInvoiceToFetchLastGeneratedDueDate
FROM CTE_MinStatementInvoiceIdToUpdateLastGeneratedDueDate MSI
LEFT JOIN ReceivableInvoiceStatementAssociations SI ON MSI.ReceivableInvoiceId = SI.ReceivableInvoiceId AND SI.StatementInvoiceId < MSI.MinStatementInvoiceId
GROUP BY MSI.ReceivableInvoiceId

UPDATE RI SET RI.LastStatementGeneratedDueDate = DATEADD(DAY, -C.InvoiceTransitDays,SI.DueDate)
FROM ReceivableInvoices RI
JOIN #EligibileStatementInvoiceToFetchLastGeneratedDueDate ESI ON RI.Id = ESI.ReceivableInvoiceId
JOIN ReceivableInvoices SI ON SI.Id = ESI.StatementInvoiceId
JOIN Customers C ON C.Id = SI.CustomerId

UPDATE RI SET RI.LastStatementGeneratedDueDate = Null
FROM ReceivableInvoices RI
JOIN #EligibileStatementInvoiceToFetchLastGeneratedDueDate ESI ON RI.Id = ESI.ReceivableInvoiceId AND ESI.StatementInvoiceId IS NULL

UPDATE ReceivableInvoiceDeliquencyDetails
SET IsOneToThirtyDaysLate = 0,
IsThirtyPlusDaysLate = 0,
IsSixtyPlusDaysLate = 0,
IsNinetyPlusDaysLate = 0,
IsOneHundredTwentyPlusDaysLate = 0
FROM ReceivableInvoiceDeliquencyDetails INNER JOIN #InvoicesToCancel 
ON ReceivableInvoiceDeliquencyDetails.ReceivableInvoiceId = #InvoicesToCancel.InvoiceId

;With ContractsOfCancelledInvoices as 
(
	select ReceivableInvoiceDetails.EntityId as ContractId FROM 
			#InvoicesToCancel INNER JOIN ReceivableInvoices ON #InvoicesToCancel.InvoiceId = ReceivableInvoices.Id
							  INNER JOIN ReceivableInvoiceDetails ON ReceivableInvoiceDetails.ReceivableInvoiceId = ReceivableInvoices.Id 
							  AND ReceivableInvoiceDetails.EntityType = 'CT'
							  group by ReceivableInvoiceDetails.EntityId
)
MERGE ContractCollectionDetails
	USING ContractsOfCancelledInvoices
		ON ContractsOfCancelledInvoices.ContractId = ContractCollectionDetails.ContractId
	WHEN MATCHED
		THEN
			UPDATE
			SET  CalculateDeliquencyDetails = 1
				,UpdatedById = @UpdatedBy
				,UpdatedTime = @UpdatedTime
	WHEN NOT MATCHED BY TARGET
		THEN
			INSERT (
				ContractId
				,OneToThirtyDaysLate
				,ThirtyPlusDaysLate
				,SixtyPlusDaysLate
				,NinetyPlusDaysLate
				,OneHundredTwentyPlusDaysLate
				,LegacyZeroPlusDaysLate
				,LegacyThirtyPlusDaysLate
				,LegacySixtyPlusDaysLate
				,LegacyNinetyPlusDaysLate
				,LegacyOneHundredTwentyPlusDaysLate
				,TotalOneToThirtyDaysLate
				,TotalThirtyPlusDaysLate
				,TotalSixtyPlusDaysLate
				,TotalNinetyPlusDaysLate
				,TotalOneHundredTwentyPlusDaysLate
				,InterestDPD
				,RentOrPrincipalDPD
				,MaturityDPD
				,OverallDPD
				,CalculateDeliquencyDetails
				,CreatedById
				,CreatedTime
				)
			VALUES (
				ContractsOfCancelledInvoices.ContractId
				,0
				,0
				,0
				,0
				,0
				,0
				,0
				,0
				,0
				,0
				,0
				,0
				,0
				,0
				,0
				,0
				,0
				,0
				,0
				,1
				,@UpdatedBy
				,@UpdatedTime
				);

CREATE TABLE #FunderReceivableComponentsUpdated(
	Id BIGINT NOT NULL
)

UPDATE RI
SET RI.IsActive = 0,
RI.CancelledById = @CancelledById,
RI.CancellationDate = @UpdatedTime,
RI.UpdatedById = @UpdatedBy,
RI.UpdatedTime = @UpdatedTime
FROM ReceivableInvoices RI
INNER JOIN #InvoicesToCancel Inv ON RI.Id = Inv.InvoiceId

UPDATE RD
SET RD.Balance_Amount = RD.Amount_Amount,
RD.EffectiveBalance_Amount = RD.Amount_Amount
OUTPUT INSERTED.Id INTO #FunderReceivableComponentsUpdated
FROM #InvoicesToCancel AS Inv
INNER JOIN ReceivableInvoiceDetails RID ON Inv.InvoiceId = RID.ReceivableInvoiceId
INNER JOIN ReceivableDetails RD ON RID.ReceivableDetailId = RD.Id
INNER JOIN Receivables ON RD.ReceivableId = Receivables.Id
WHERE Receivables.IsServiced = 1
AND Receivables.IsCollected = 0
AND Receivables.FunderId IS NOT NULL

UPDATE RDWD SET 
	RDWD.Balance_Amount = RDWD.Tax_Amount,
	RDWD.EffectiveBalance_Amount = RDWD.Tax_Amount
FROM ReceivableDetailsWithholdingTaxDetails RDWD 
INNER JOIN #FunderReceivableComponentsUpdated F ON RDWD.ReceivableDetailId=F.Id AND RDWD.IsActive=1

TRUNCATE TABLE #FunderReceivableComponentsUpdated;

UPDATE RD
SET RD.BilledStatus = @BilledStatus,
RD.UpdatedById = @UpdatedBy,
RD.UpdatedTime = @UpdatedTime
FROM ReceivableDetails RD
INNER JOIN ReceivableInvoiceDetails RID ON RD.Id = RID.ReceivableDetailId
INNER JOIN #InvoicesToCancel Inv ON RID.ReceivableInvoiceId = Inv.InvoiceId

UPDATE RTI
SET RTI.Balance_Amount = RTI.Amount_Amount,
RTI.EffectiveBalance_Amount = RTI.Amount_Amount,
RTI.UpdatedById = @UpdatedBy,
RTI.UpdatedTime = @UpdatedTime
FROM #InvoicesToCancel AS II
INNER JOIN ReceivableInvoiceDetails RID ON II.InvoiceId = RID.ReceivableInvoiceId
INNER JOIN ReceivableDetails RD ON RID.ReceivableDetailId = RD.Id
INNER JOIN Receivables ON RD.ReceivableId = Receivables.Id
INNER JOIN ReceivableTaxDetails RTD ON RD.Id = RTD.ReceivableDetailId
INNER JOIN ReceivableTaxImpositions RTI ON RTD.Id = RTI.ReceivableTaxDetailId
WHERE Receivables.IsServiced = 1
AND Receivables.IsCollected = 0
AND Receivables.FunderId IS NOT NULL

UPDATE lfa
SET
lfa.LateFeeAssessedUntilDate = ri.DueDate,
lfa.UpdatedById = @UpdatedBy,
lfa.UpdatedTime = @UpdatedTime
FROM #InvoicesToCancel I
INNER JOIN dbo.ReceivableInvoices ri ON I.InvoiceId = ri.Id
INNER JOIN dbo.LateFeeAssessments lfa ON ri.Id = lfa.ReceivableInvoiceId
WHERE lfa.IsActive = 1

UPDATE rid
SET
rid.IsActive = 0,
rid.UpdatedById = @UpdatedBy,
rid.UpdatedTime = @UpdatedTime
FROM #InvoicesToCancel I
INNER JOIN dbo.ReceivableInvoices ri ON I.InvoiceId = ri.Id
INNER JOIN dbo.ReceivableInvoiceDetails rid ON rid.ReceivableInvoiceId = ri.Id
WHERE rid.IsActive = 1

UPDATE Receivables
SET TotalBalance_Amount = Receivables.TotalAmount_Amount
,TotalEffectiveBalance_Amount = Receivables.TotalAmount_Amount
,UpdatedById = @UpdatedBy
,UpdatedTime = @UpdatedTime
OUTPUT INSERTED.Id INTO #FunderReceivableComponentsUpdated
FROM #InvoicesToCancel AS I
INNER JOIN ReceivableInvoiceDetails RID ON I.InvoiceId = RID.ReceivableInvoiceId
INNER JOIN ReceivableDetails RD ON RID.ReceivableDetailId = RD.Id
INNER JOIN Receivables ON RD.ReceivableId = Receivables.Id
WHERE Receivables.IsServiced = 1
AND Receivables.IsCollected = 0
AND Receivables.FunderId IS NOT NULL

UPDATE RWD SET 
	RWD.Balance_Amount = RWD.Tax_Amount,
	RWD.EffectiveBalance_Amount = RWD.Tax_Amount
FROM ReceivableWithholdingTaxDetails RWD 
INNER JOIN #FunderReceivableComponentsUpdated F ON RWD.ReceivableId=F.Id AND RWD.IsActive=1

UPDATE RTD
SET Balance_Amount = RTD.Amount_Amount
,EffectiveBalance_Amount = RTD.Amount_Amount
,UpdatedById = @UpdatedBy
,UpdatedTime = @UpdatedTime
FROM #InvoicesToCancel AS I
INNER JOIN ReceivableInvoiceDetails RID ON I.InvoiceId = RID.ReceivableInvoiceId
INNER JOIN ReceivableDetails RD ON RID.ReceivableDetailId = RD.Id
INNER JOIN Receivables ON RD.ReceivableId = Receivables.Id
INNER JOIN ReceivableTaxDetails RTD ON RD.Id = RTD.ReceivableDetailId
WHERE Receivables.IsServiced = 1
AND Receivables.IsCollected = 0
AND Receivables.FunderId IS NOT NULL

UPDATE RT
SET Balance_Amount = RT.Amount_Amount
,EffectiveBalance_Amount = RT.Amount_Amount
,UpdatedById = @UpdatedBy
,UpdatedTime = @UpdatedTime
FROM #InvoicesToCancel AS I
INNER JOIN ReceivableInvoiceDetails RID ON I.InvoiceId = RID.ReceivableInvoiceId
INNER JOIN ReceivableDetails RD ON RID.ReceivableDetailId = RD.Id
INNER JOIN Receivables ON RD.ReceivableId = Receivables.Id
INNER JOIN ReceivableTaxes RT ON Receivables.Id = RT.ReceivableId
WHERE Receivables.IsServiced = 1
AND Receivables.IsCollected = 0
AND Receivables.FunderId IS NOT NULL

UPDATE RT
	 SET Balance_Amount = RT.Amount_Amount
	,EffectiveBalance_Amount = RT.Amount_Amount
	,UpdatedById = @UpdatedBy
	,UpdatedTime = @UpdatedTime
FROM #InvoicesToCancel AS II
INNER JOIN ReceivableInvoiceDetails RID ON II.InvoiceId = RID.ReceivableInvoiceId
INNER JOIN ReceivableDetails RD ON RID.ReceivableDetailId = RD.Id
INNER JOIN Receivables R ON RD.ReceivableId = R.Id
INNER JOIN ReceivableTaxes RT ON R.Id=RT.ReceivableId
INNER JOIN TiedContractPaymentDetails TPD on R.PaymentScheduleId=TPD.PaymentScheduleId AND TPD.ContractId=R.EntityId AND TPD.IsActive=1
LEFT JOIN LeasePaymentSchedules LeasePaymentSchedule on R.PaymentScheduleId=LeasePaymentSchedule.Id
LEFT JOIN LoanPaymentSchedules LoanPaymentSchedule on R.PaymentScheduleId=LoanPaymentSchedule.Id
WHERE R.IsServiced = 1
AND R.IsCollected = 0
AND R.FunderId IS NULL
AND (LeasePaymentSchedule.Id IS NOT NULL OR LoanPaymentSchedule.Id IS NOT null)

UPDATE RTD
	SET Balance_Amount = RTD.Amount_Amount
	,EffectiveBalance_Amount = RTD.Amount_Amount
	,UpdatedById = @UpdatedBy
	,UpdatedTime = @UpdatedTime
FROM #InvoicesToCancel AS II
INNER JOIN ReceivableInvoiceDetails RID ON II.InvoiceId = RID.ReceivableInvoiceId
INNER JOIN ReceivableDetails RD ON RID.ReceivableDetailId = RD.Id
INNER JOIN Receivables R ON RD.ReceivableId = R.Id
INNER JOIN ReceivableTaxDetails RTD ON RD.Id = RTD.ReceivableDetailId
INNER JOIN TiedContractPaymentDetails TPD on R.PaymentScheduleId=TPD.PaymentScheduleId AND TPD.ContractId=R.EntityId AND TPD.IsActive=1
LEFT JOIN LeasePaymentSchedules LeasePaymentSchedule on R.PaymentScheduleId=LeasePaymentSchedule.Id
LEFT JOIN LoanPaymentSchedules LoanPaymentSchedule on R.PaymentScheduleId=LoanPaymentSchedule.Id
WHERE R.IsServiced = 1
AND R.IsCollected = 0
AND R.FunderId IS NULL
AND (LeasePaymentSchedule.Id IS NOT NULL OR LoanPaymentSchedule.Id IS NOT null)


UPDATE RTI
SET Balance_Amount = RTI.Amount_Amount,
EffectiveBalance_Amount = RTI.Amount_Amount,
UpdatedById = @UpdatedBy,
UpdatedTime = @UpdatedTime
FROM #InvoicesToCancel AS II
INNER JOIN ReceivableInvoiceDetails RID ON II.InvoiceId = RID.ReceivableInvoiceId
INNER JOIN ReceivableDetails RD ON RID.ReceivableDetailId = RD.Id
INNER JOIN Receivables R ON RD.ReceivableId = R.Id
INNER JOIN ReceivableTaxDetails RTD ON RD.Id = RTD.ReceivableDetailId
INNER JOIN ReceivableTaxImpositions RTI ON RTD.Id = RTI.ReceivableTaxDetailId
INNER JOIN TiedContractPaymentDetails TPD on R.PaymentScheduleId=TPD.PaymentScheduleId AND TPD.ContractId=R.EntityId AND TPD.IsActive=1
LEFT JOIN LeasePaymentSchedules LeasePaymentSchedule on R.PaymentScheduleId=LeasePaymentSchedule.Id
LEFT JOIN LoanPaymentSchedules LoanPaymentSchedule on R.PaymentScheduleId=LoanPaymentSchedule.Id
WHERE R.IsServiced = 1
AND R.IsCollected = 0
AND R.FunderId IS NULL
AND (LeasePaymentSchedule.Id IS NOT NULL OR LoanPaymentSchedule.Id IS NOT null)

UPDATE RWTD
SET Balance_Amount = RWTD.Tax_Amount,
EffectiveBalance_Amount = RWTD.Tax_Amount,
UpdatedById = @UpdatedBy,
UpdatedTime = @UpdatedTime
FROM #InvoicesToCancel AS II
INNER JOIN ReceivableInvoiceDetails RID ON II.InvoiceId = RID.ReceivableInvoiceId
INNER JOIN ReceivableDetails RD ON RID.ReceivableDetailId = RD.Id
INNER JOIN Receivables R ON RD.ReceivableId = R.Id
INNER JOIN ReceivableWithholdingTaxDetails RWTD ON RWTD.ReceivableId=R.Id
INNER JOIN TiedContractPaymentDetails TPD on R.PaymentScheduleId=TPD.PaymentScheduleId AND TPD.ContractId=R.EntityId AND TPD.IsActive=1
LEFT JOIN LeasePaymentSchedules LeasePaymentSchedule on R.PaymentScheduleId=LeasePaymentSchedule.Id
LEFT JOIN LoanPaymentSchedules LoanPaymentSchedule on R.PaymentScheduleId=LoanPaymentSchedule.Id
WHERE R.IsServiced = 1
AND R.IsCollected = 0
AND R.FunderId IS NULL
AND (LeasePaymentSchedule.Id IS NOT NULL OR LoanPaymentSchedule.Id IS NOT null)

UPDATE RDWTD
SET Balance_Amount = RDWTD.Tax_Amount,
EffectiveBalance_Amount = RDWTD.Tax_Amount,
UpdatedById = @UpdatedBy,
UpdatedTime = @UpdatedTime
FROM #InvoicesToCancel AS II
INNER JOIN ReceivableInvoiceDetails RID ON II.InvoiceId = RID.ReceivableInvoiceId
INNER JOIN ReceivableDetails RD ON RID.ReceivableDetailId = RD.Id
INNER JOIN Receivables R ON RD.ReceivableId = R.Id
INNER JOIN ReceivableDetailsWithholdingTaxDetails RDWTD ON RDWTD.ReceivableDetailId=RD.Id
INNER JOIN TiedContractPaymentDetails TPD on R.PaymentScheduleId=TPD.PaymentScheduleId AND TPD.ContractId=R.EntityId AND TPD.IsActive=1
LEFT JOIN LeasePaymentSchedules LeasePaymentSchedule on R.PaymentScheduleId=LeasePaymentSchedule.Id
LEFT JOIN LoanPaymentSchedules LoanPaymentSchedule on R.PaymentScheduleId=LoanPaymentSchedule.Id
WHERE R.IsServiced = 1
AND R.IsCollected = 0
AND R.FunderId IS NULL
AND (LeasePaymentSchedule.Id IS NOT NULL OR LoanPaymentSchedule.Id IS NOT null)


UPDATE RI
SET
TaxBalance_Amount = RI.InvoiceTaxAmount_Amount,
EffectiveTaxBalance_Amount = RI.InvoiceTaxAmount_Amount,
UpdatedById = @UpdatedBy,
UpdatedTime = @UpdatedTime
FROM #InvoicesToCancel AS II
INNER JOIN ReceivableInvoiceDetails RID ON II.InvoiceId = RID.ReceivableInvoiceId
INNER JOIN ReceivableDetails RD ON RID.ReceivableDetailId = RD.Id
INNER JOIN Receivables R ON RD.ReceivableId = R.Id	
INNER JOIN ReceivableInvoices RI ON RI.Id=RID.ReceivableInvoiceId
INNER JOIN TiedContractPaymentDetails TPD on R.PaymentScheduleId=TPD.PaymentScheduleId AND TPD.ContractId=R.EntityId AND TPD.IsActive=1
LEFT JOIN LeasePaymentSchedules LeasePaymentSchedule on R.PaymentScheduleId=LeasePaymentSchedule.Id
LEFT JOIN LoanPaymentSchedules LoanPaymentSchedule on R.PaymentScheduleId=LoanPaymentSchedule.Id
WHERE R.IsServiced = 1
AND R.IsCollected = 0
AND R.FunderId IS NULL
AND (LeasePaymentSchedule.Id IS NOT NULL OR LoanPaymentSchedule.Id IS NOT null)

UPDATE RID
SET TaxBalance_Amount = RID.InvoiceTaxAmount_Amount,
EffectiveTaxBalance_Amount = RID.InvoiceTaxAmount_Amount,
UpdatedById = @UpdatedBy,
UpdatedTime = @UpdatedTime
FROM #InvoicesToCancel AS II
INNER JOIN ReceivableInvoiceDetails RID ON II.InvoiceId = RID.ReceivableInvoiceId
INNER JOIN ReceivableDetails RD ON RID.ReceivableDetailId = RD.Id
INNER JOIN Receivables R ON RD.ReceivableId = R.Id
INNER JOIN TiedContractPaymentDetails TPD on R.PaymentScheduleId=TPD.PaymentScheduleId AND TPD.ContractId=R.EntityId AND TPD.IsActive=1
LEFT JOIN LeasePaymentSchedules LeasePaymentSchedule on R.PaymentScheduleId=LeasePaymentSchedule.Id
LEFT JOIN LoanPaymentSchedules LoanPaymentSchedule on R.PaymentScheduleId=LoanPaymentSchedule.Id
WHERE R.IsServiced = 1
AND R.IsCollected = 0
AND R.FunderId IS NULL
AND (LeasePaymentSchedule.Id IS NOT NULL OR LoanPaymentSchedule.Id IS NOT null)


SELECT
SRI.StatementInvoiceId,
Balance_Amount = ISNULL(SUM(RI.Balance_Amount), 0),
TaxBalance_Amount = ISNULL(SUM(TaxBalance_Amount),0),
EffectiveBalance_Amount = ISNULL(SUM(EffectiveBalance_Amount),0),
EffectiveTaxBalance_Amount = ISNULL(SUM(EffectiveTaxBalance_Amount), 0),
WithHoldingTaxBalance_Amount = ISNULL(SUM(WithHoldingTaxBalance_Amount),0)
INTO #StatementInvoicesUpdateAmount
FROM #StatementInvoicesOfReceivableInvoices SRI
INNER JOIN ReceivableInvoiceStatementAssociations RSI ON SRI.StatementInvoiceId = RSI.StatementInvoiceID
LEFT JOIN ReceivableInvoices RI ON RSI.ReceivableInvoiceId = RI.Id AND RI.IsActive =1
GROUP BY SRI.StatementInvoiceId

UPDATE RI
SET Balance_Amount =  SRI.Balance_Amount,
TaxBalance_Amount = SRI.TaxBalance_Amount,
EffectiveBalance_Amount = SRI.EffectiveBalance_Amount,
EffectiveTaxBalance_Amount = SRI.EffectiveTaxBalance_Amount,
WithHoldingTaxBalance_Amount = SRI.WithHoldingTaxBalance_Amount
FROM ReceivableInvoices RI
INNER JOIN #StatementInvoicesUpdateAmount SRI ON RI.Id = SRI.StatementInvoiceId

IF ((SELECT COUNT(*) FROM #CashPostedInvoices) > 0 AND @jobStepInstanceId IS NOT NULL)
BEGIN
	DECLARE @InvoiceNumberCsv NVARCHAR(MAX)
	SELECT @InvoiceNumberCsv = COALESCE(@InvoiceNumberCsv + ',', '') +  CONVERT(VARCHAR(12),ri.Number)
	FROM dbo.ReceivableInvoices ri
	WHERE ri.Id IN (SELECT cpi.InvoiceId from #CashPostedInvoices cpi)
	ORDER BY ri.Number
	INSERT INTO dbo.JobStepInstanceLogs(Message,MessageType,CreatedById,CreatedTime,UpdatedById,UpdatedTime,JobStepInstanceId)
	VALUES (CONCAT('Invoice Number(s) {', @InvoiceNumberCsv ,'} cannot be cancelled because cash has been posted/Pending receipt created against them'),
	N'Error', @UpdatedBy, @UpdatedTime, NULL, NULL, @jobStepInstanceId)
END

IF ((SELECT COUNT(*) FROM #InvoiceAsPartOfOneTimeACH) > 0 AND @jobStepInstanceId IS NOT NULL)
BEGIN
	DECLARE @InvoiceNumberCsv1 NVARCHAR(MAX)
	DECLARE @OneTimeACHId BIGINT
	DECLARE @TotalOneTimeACHes BIGINT = (SELECT COUNT(DISTINCT OnetimeACHId) FROM #InvoiceAsPartOfOneTimeACH)
	WHILE(@TotalOneTimeACHes>0)
	BEGIN
		SELECT @OneTimeACHId = otach.Id
		FROM dbo.OneTimeACHes otach
		WHERE otach.Id IN (SELECT top(1) OnetimeACHId from #InvoiceAsPartOfOneTimeACH ORDER BY OnetimeACHId)

		SET @InvoiceNumberCsv1 = NULL

		SELECT @InvoiceNumberCsv1 = COALESCE(@InvoiceNumberCsv1 + ',', '') +  CONVERT(VARCHAR(12),ri.Number)
		FROM dbo.ReceivableInvoices ri
		WHERE ri.Id IN (SELECT InvoiceId from #InvoiceAsPartOfOneTimeACH WHERE OnetimeACHId = @OneTimeACHId)

		INSERT INTO dbo.JobStepInstanceLogs(Message,MessageType,CreatedById,CreatedTime,UpdatedById,UpdatedTime,JobStepInstanceId)
		VALUES (CONCAT('The given Invoice (Invoice#) {', @InvoiceNumberCsv1 ,'} cannot be cancelled as it is already associated to a One-Time ACH (OTACH#){', CONVERT(varchar(10),@OneTimeACHId) , '}'),
		N'Error', @UpdatedBy, @UpdatedTime, NULL, NULL, @jobStepInstanceId)

		SET @TotalOneTimeACHes = @TotalOneTimeACHes -1

		DELETE FROM #InvoiceAsPartOfOneTimeACH WHERE OnetimeACHId = @OneTimeACHId
	END
END

IF ((SELECT COUNT(*) FROM #LateFeeInvoices) > 0 AND @jobStepInstanceId IS NOT NULL)
BEGIN
	DECLARE @InvoiceNumbersCsv nvarchar(max)

	SELECT @InvoiceNumbersCsv = COALESCE(@InvoiceNumbersCsv + ',', '') +  CONVERT(VARCHAR(12),ri.Number)
	FROM dbo.ReceivableInvoices ri
	WHERE ri.Id IN (SELECT lfi.InvoiceId FROM #LateFeeInvoices lfi)
	ORDER BY ri.Number

	INSERT INTO dbo.JobStepInstanceLogs(Message,MessageType,CreatedById,CreatedTime,UpdatedById,UpdatedTime,JobStepInstanceId)
	VALUES (CONCAT('Invoice Number(s) {', @InvoiceNumbersCsv ,'} cannot be cancelled because Late fee receivables were assessed against them. Please reverse the same before proceeding further'),
	N'Error', @UpdatedBy, @UpdatedTime, NULL, NULL, @jobStepInstanceId)
END

IF ((SELECT COUNT(*) FROM #InvoicesToCancel ) > 0 AND @jobStepInstanceId IS NOT NULL)
BEGIN
	DECLARE @InvoiceCount INT;

	SET @InvoiceCount = (SELECT COUNT(*) FROM #InvoicesToCancel);

	INSERT INTO dbo.JobStepInstanceLogs(Message,MessageType,CreatedById,CreatedTime,UpdatedById,UpdatedTime,JobStepInstanceId)
	VALUES (CONCAT(@InvoiceCount ,' Invoice(s) have been cancelled'),
	N'Information', @UpdatedBy, @UpdatedTime, NULL, NULL, @jobStepInstanceId)
END

DROP TABLE #Invoices
DROP TABLE #CashPostedInvoices
DROP TABLE #LateFeeInvoices
DROP TABLE #InvoicesToCancel
DROP TABLE #InvoicesWithoutCashpostedInvoices
DROP TABLE #InvoicesToCancelTemp
DROP TABLE #AlreadyCancelledInvoices
DROP TABLE #InvoiceAsPartOfOneTimeACH
DROP TABLE #StatementInvoiceAssociatedReceivableInvoices
DROP TABLE #AllAssociatedStatementInvoices
DROP TABLE #StatementInvoiceAssociatedReceivableInvoicesForUpdating
DROP TABLE #FunderReceivableComponentsUpdated
DROP TABLE #InvoiceIds
DROP TABLE #StatementInvoicesOfReceivableInvoices
DROP TABLE #EligibileStatementInvoiceToFetchLastGeneratedDueDate
DROP TABLE #StatementInvoicesUpdateAmount

COMMIT TRANSACTION
END TRY
BEGIN CATCH
ROLLBACK TRANSACTION;
END CATCH
END

GO
