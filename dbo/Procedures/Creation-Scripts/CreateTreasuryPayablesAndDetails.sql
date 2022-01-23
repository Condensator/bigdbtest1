SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[CreateTreasuryPayablesAndDetails]
(
@TreasuryPayablesInfo TreasuryPayableInfo READONLY,
@CreatedById BIGINT,
@CreatedTime DATETIMEOFFSET(7)
)
AS
SET NOCOUNT ON;
CREATE TABLE #PersistedTreasuryPayable
(
[Key] BIGINT,
[PayableId] BIGINT,
[Id] BIGINT
)
SELECT
TP.[Key] as [Key] , P.Id as PayableId , P.DueDate , P.Amount_Amount , P.Amount_Currency,P.Balance_Amount , P.Balance_Currency,
TP.TreasuryPayableStatus, TP.ApprovalComment , TP.Urgency  , TP.Memo , TP.Comment , TP.ReceiptType,P.LegalEntityId , P.CurrencyId,
P.PayeeId , P.RemitToId , TP.PayFromAccountId , TP.MailingInstruction , TP.ContractSequenceNumber , TP.PayableInvoiceNumber  ,TP.TransactionNumber
INTO #TempPayableInfo FROM Payables P
join @TreasuryPayablesInfo TP on P.[Id] = TP.[PayableId]
MERGE TreasuryPayables TP
USING #TempPayableInfo TPI
ON 1 = 0
WHEN NOT MATCHED
THEN
INSERT
([RequestedPaymentDate]
,[Amount_Amount]
,[Amount_Currency]
,[Balance_Amount]
,[Balance_Currency]
,[Status]
,[ApprovalComment]
,[Urgency]
,[Memo]
,[Comment]
,[ReceiptType]
,[CreatedById]
,[CreatedTime]
,[UpdatedById]
,[UpdatedTime]
,[LegalEntityId]
,[CurrencyId]
,[PayeeId]
,[RemitToId]
,[PayFromAccountId]
,[MailingInstruction]
,[ContractSequenceNumber]
,[PayableInvoiceNumber]
,[TransactionNumber])
VALUES
(TPI.DueDate
,TPI.Amount_Amount
,TPI.Amount_Currency
,TPI.Balance_Amount
,TPI.Balance_Currency
,TPI.TreasuryPayableStatus
,TPI.ApprovalComment
,TPI.Urgency
,TPI.Memo
,TPI.Comment
,TPI.ReceiptType
,@CreatedById
,@CreatedTime
,NULL
,NULL
,TPI.LegalEntityId
,TPI.CurrencyId
,TPI.PayeeId
,TPI.RemitToId
,TPI.PayFromAccountId
,TPI.MailingInstruction
,TPI.ContractSequenceNumber
,TPI.PayableInvoiceNumber
,TPI.TransactionNumber
)
OUTPUT TPI.[Key] as [Key], TPI.PayableId AS [PayableId], INSERTED.Id AS [Id] INTO #PersistedTreasuryPayable;
SELECT TPP.ReceivableOffsetAmount,TP.Amount_Currency AS Currency,PTP.PayableId,TP.Id AS TreasuryPayableId
INTO #TempPayableDetailInfo FROM TreasuryPayables TP
join #PersistedTreasuryPayable PTP on TP.[Id] = PTP.[Id]
join @TreasuryPayablesInfo TPP on PTP.[PayableId] = TPP.[PayableId]
INSERT INTO TreasuryPayableDetails
([IsActive]
,[ReceivableOffsetAmount_Amount]
,[ReceivableOffsetAmount_Currency]
,[CreatedById]
,[CreatedTime]
,[UpdatedById]
,[UpdatedTime]
,[PayableId]
,[DisbursementRequestPayableId]
,[TreasuryPayableId])
SELECT
1
,TPDI.ReceivableOffsetAmount
,TPDI.Currency
,@CreatedById
,@CreatedTime
,NULL
,NULL
,TPDI.PayableId
,NULL
,TPDI.TreasuryPayableId
FROM #TempPayableDetailInfo TPDI
SELECT * FROM #PersistedTreasuryPayable;
DROP TABLE #PersistedTreasuryPayable;

GO
