SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[PopulateNonCashGLForPropertyTax]
(
@CreatedTime DATETIMEOFFSET = NULL
)
AS
BEGIN
SET NOCOUNT ON
IF(@CreatedTime IS NULL)
SET @CreatedTime = SYSDATETIMEOFFSET();
--DROP TABLE #GlHelp
--DROP TABLE #GeneralDetails
--TODO : Check The Contract has any PPT Escrow receivables then we should do Non Cash GL Entries
CREATE TABLE #GeneralDetails
(
StagingEntityId BIGINT
,ContractId BIGINT
,LegalEntityId INT
,LOBId INT
,NonCashGLTemplateId INT
,AccountTypeId INT
,BankAccountId INT
,InstrumentTypeId INT
,CustomerId BIGINT
,NonCashReason NVARCHAR(100)
,EscrowGLTemplateId INT
,ContractSequenceNumber NVARCHAR(40)
,Amount_Amount DECIMAL(18,2)
,Amount_Currency NVARCHAR(3)
--,IsDebit BIT
--,AccountNumber NVARCHAR(100)
,CurrencyId INT
,ReceiptTypeId INT
)
CREATE TABLE #GlHelp
(
EntryItemId INT
,GlTemplateDetailId INT
,AccountId INT
,IsDebit BIT
,AccountNumber NVARCHAR(100)
,ContractSequenceNumber NVARCHAR(100)
,ContractId BIGINT
)
CREATE TABLE #Temp
(
ReceivableId BIGINT
,ReceivableDetailId BIGINT
,Balance DECIMAL(18,2)
,IsUpdated TINYINT
)
DECLARE @ReceiptTypeId INT
DECLARE @ReceiptGLTemplateId INT
DECLARE @EscrowGlTemplateId INT
SELECT @ReceiptTypeId = Id FROM ReceiptTypes WHERE ReceiptTypeName = 'PPTEscrowNonCash'
SELECT @ReceiptGLTemplateId = GLTemplateId FROM ReceiptNonCashTemplates WHERE NonCashTypeId = @ReceiptTypeId
INSERT INTO #GeneralDetails
SELECT DISTINCT
PPTGL.Id
,Contracts.Id
,LF.LegalEntityId
,Contracts.LineofBusinessId
,@ReceiptGLTemplateId --NonCashGLTemplateId
,1 --AccountTypeId
,1 --BankAccountId
,LF.InstrumentTypeId
,LF.CustomerId
,'Courtesy'
,1
,Contracts.SequenceNumber
,PPTGL.Amount_Amount
,PPTGL.Amount_Currency
,Contracts.CurrencyId
,@ReceiptTypeId
FROM Contracts
JOIN LW_Intermediate..PropertyTaxNonCashGL PPTGL ON Contracts.SequenceNumber = PPTGL.ContractSequenceNumber
JOIN LeaseFinances LF ON Contracts.Id = LF.ContractId
JOIN LegalEntities ON LF.LegalEntityId = LegalEntities.Id AND LF.LegalEntityId = LegalEntities.Id
JOIN Sundries ON Contracts.Id = Sundries.ContractId AND Sundries.LegalEntityId = LegalEntities.Id
WHERE LF.IsCurrent = 1 AND Type='PPTEscrow' AND IsMigrated = 0
--UPDATE GD SET CurrencyId = C.Id FROM #GeneralDetails GD
--JOIN CurrencyCodes CC ON GD.Amount_Currency = CC.ISO
--JOIN Currencies C ON CC.Id = C.CurrencyCodeId
--SELECT * FROM #GeneralDetails GD
--JOIN CurrencyCodes CC ON GD.Amount_Currency = CC.ISO
--JOIN Currencies C ON CC.Id = C.CurrencyCodeId
UPDATE GD SET EscrowGLTemplateId = GLTemplateId FROM #GeneralDetails GD
JOIN Sundries ON GD.ContractId = Sundries.ContractId AND Sundries.IsActive = 1
JOIN ReceivableCodes ON Sundries.ReceivableCodeId = ReceivableCodes.Id
--SELECT GLTemplateId FROM #GeneralDetails GD
--JOIN Sundries ON GD.ContractId = Sundries.ContractId AND Sundries.IsActive = 1
--JOIN ReceivableCodes ON Sundries.ReceivableCodeId = ReceivableCodes.Id
;WITH CTE_GL AS
(
SELECT EntryItemId,GLTemplateDetails.Id GlTemplateDetailId,GLAccountId,IsDebit FROM GLTemplates
JOIN GLTemplateDetails ON GLTemplates.Id = GLTemplateDetails.GLTemplateId
JOIN GLEntryItems ON GLTemplateDetails.EntryItemId = GLEntryItems.Id
WHERE GLTemplateId = @ReceiptGLTemplateId AND GLEntryItems.Name IN ('PPTEscrow','Receivable')
)
--SELECT * FROM CTE_GL
INSERT INTO #GlHelp(EntryItemId,GlTemplateDetailId,AccountId,IsDebit,AccountNumber,ContractSequenceNumber)
SELECT EntryItemId,CTE_GL.GlTemplateDetailId,CTE_GL.GLAccountId,CTE_GL.IsDebit,CASE WHEN IsDebit = 1 THEN PT.DebitGLAccount ELSE PT.CreditGLAccount END AS AccountNumber
,PT.ContractSequenceNumber
FROM CTE_GL,LW_Intermediate..PropertyTaxNonCashGL PT
WHERE PT.IsMigrated = 0
UPDATE #GlHelp SET ContractId = Id FROM #GlHelp JOIN Contracts ON Contracts.SequenceNumber = #GlHelp.ContractSequenceNumber
--SELECT * FROM #GeneralDetails
--SELECT * FROM PropertyTaxNonCashGL
--SELECT * FROM #GlHelp
DECLARE @ContractId BIGINT
DECLARE @ReceiptId BIGINT
DECLARE @GLJournalId BIGINT
DECLARE CUR CURSOR LOCAL READ_ONLY FORWARD_ONLY FOR
SELECT ContractId FROM #GeneralDetails
OPEN CUR
FETCH NEXT FROM CUR INTO @ContractId
WHILE @@FETCH_STATUS = 0
BEGIN
--SELECT @ContractId
INSERT INTO Receipts
(
Number
,ReceiptAmount_Amount
,ReceiptAmount_Currency
,EntityType
,PostDate
,ReceivedDate
,Status
,CreateRefund
,CreatedById
,CreatedTime
,LegalEntityId
,CurrencyId
,TypeId
,ContractId
,ReceiptGLTemplateId
,Balance_Amount
,Balance_Currency
,ApplyByReceivable
,NonCashReason
,IsFromReceiptBatch
,ReceiptClassification
,SecurityDepositLiabilityContractAmount_Amount
,SecurityDepositLiabilityContractAmount_Currency
,SecurityDepositLiabilityAmount_Amount
,SecurityDepositLiabilityAmount_Currency
)
SELECT
CAST(CAST(ContractId AS NVARCHAR(20)) + CAST(StagingEntityId AS NVARCHAR(10)) AS BIGINT)
,Amount_Amount
,Amount_Currency
,'Lease'
,GETDATE()
,GETDATE()
,'Completed'
,0
,1
,@CreatedTime
,LegalEntityId
,CurrencyId
,ReceiptTypeId
,ContractId
,NonCashGLTemplateId
,0
,Amount_Currency
,1
,NonCashReason
,0
,'NonCash'
,0
,Amount_Currency
,0
,Amount_Currency
FROM #GeneralDetails WHERE ContractId = @ContractId
SET @ReceiptId = SCOPE_IDENTITY();
INSERT INTO GLJournals
(
PostDate
,IsManualEntry
,IsReversalEntry
,CreatedById
,CreatedTime
,LegalEntityId
)
SELECT
GETDATE(),0,0,1,@CreatedTime,LegalEntityId
FROM #GeneralDetails WHERE ContractId = @ContractId
SET @GLJournalId = SCOPE_IDENTITY();
INSERT INTO ReceiptGLJournals
(
PostDate,IsReversal ,CreatedById,CreatedTime,LegalEntityId,GLJournalId,ReceiptId
)
SELECT GETDATE(),0,1,@CreatedTime,LegalEntityId,@GLJournalId,@ReceiptId
FROM #GeneralDetails WHERE ContractId = @ContractId
INSERT INTO GLJournalDetails
(
EntityId
,EntityType
,Amount_Amount
,Amount_Currency
,IsDebit
,GLAccountNumber
,Description
,SourceId
,CreatedById
,CreatedTime
,GLAccountId
,GLTemplateDetailId
,MatchingGLTemplateDetailId
,GLJournalId
,IsActive
)
SELECT
#GlHelp.ContractId,'Contract',Amount_Amount,Amount_Currency,IsDebit,AccountNumber,'Property Tax NonCash',@ReceiptId,1,@CreatedTime,ISNULL(AccountId,1),GlTemplateDetailId,NULL,@GLJournalId,1
FROM #GeneralDetails
JOIN #GlHelp ON #GlHelp.ContractId = #GeneralDetails.ContractId
WHERE #GlHelp.ContractId = @ContractId
/* Update Receivable Balance */
DECLARE @ReceivableDetailId bigint
DECLARE @Balance decimal(18,2)
DECLARE @Amount DECIMAL(18,2)
INSERT INTO #Temp
SELECT Receivables.Id ReceivableId, ReceivableDetails.Id ReceivableDetailId, ReceivableDetails.Balance_Amount Balance,0 AS IsUpdated
FROM Receivables
JOIN Sundries ON Sundries.ReceivableId = Receivables.Id AND Sundries.Id = Receivables.SourceId
JOIN ReceivableDetails ON Receivables.Id = ReceivableDetails.ReceivableId
--JOIN #GeneralDetails ON #GeneralDetails.ContractId = Receivables.EntityId
WHERE Receivables.EntityType='CT' and Receivables.IsActive = 1 and ReceivableDetails.IsActive = 1 AND ReceivableDetails.Balance_Amount > 0 and Sundries.IsActive = 1
AND EntityId = @ContractId AND Receivables.SourceTable = 'Sundry' AND Type='PPTEscrow'
SELECT @Amount = PPT.Amount_Amount FROM COntracts
JOIN LW_Intermediate..PropertyTaxNonCashGL PPT ON PPT.ContractSequenceNumber = Contracts.SequenceNumber
WHERE Contracts.Id = @ContractId
--SELECT * from #Temp ORDER BY ReceivableId,ReceivableDetailId
DECLARE @MyCursor CURSOR
SET @MyCursor = CURSOR FAST_FORWARD
FOR
SELECT ReceivableDetailId, Balance FROM #Temp WHERE IsUpdated = 0 ORDER BY ReceivableId,ReceivableDetailId
OPEN @MyCursor
FETCH NEXT FROM @MyCursor INTO @ReceivableDetailId,@Balance
WHILE @@FETCH_STATUS = 0 AND @Amount > 0
BEGIN
UPDATE ReceivableDetails SET Balance_Amount = (CASE WHEN Balance_Amount - @Amount < 0 THEN 0 ELSE Balance_Amount - @Amount END),
EffectiveBalance_Amount = (CASE WHEN EffectiveBalance_Amount - @Amount < 0 THEN 0 ELSE EffectiveBalance_Amount - @Amount END ) WHERE Id = @ReceivableDetailId
UPDATE #Temp SET IsUpdated= 1 WHERE ReceivableDetailId = @ReceivableDetailId AND IsUpdated = 0
SET @Amount = @Amount - @Balance
FETCH NEXT FROM @MyCursor
INTO @ReceivableDetailId,@Balance
END
CLOSE @MyCursor
DEALLOCATE @MyCursor;
WITH CTE_GroupedReceivables AS
(
SELECT ReceivableId, SUM(Balance_Amount) Balance, SUM(EffectiveBalance_Amount) EffectiveBalance
--INTO #GroupedReceivables
FROM ReceivableDetails WHERE Id IN (SELECT ReceivableDetailId FROM #Temp)
GROUP by ReceivableId
)
--SELECT * FROM CTE_GroupedReceivables
UPDATE Receivables SET TotalBalance_Amount = CTE_GroupedReceivables.Balance, TotalEffectiveBalance_Amount = CTE_GroupedReceivables.EffectiveBalance from CTE_GroupedReceivables
INNER JOIN Receivables ON CTE_GroupedReceivables.ReceivableId = Receivables.Id
UPDATE LW_Intermediate..propertytaxnoncashGL SET IsMigrated = 1 WHERE ContractSequenceNumber IN (SELECT SequenceNumber FROM Contracts WHERE Id=@ContractId)
FETCH NEXT FROM CUR INTO @ContractId
END
CLOSE CUR
DEALLOCATE CUR
--drop table #Temp
--drop table #GroupedReceivables
END

GO
