SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[GetLeaseContratctPayablesForPostScheduleFundingJob]
(
@LegalEntityIds LegalEntityIdCollection Readonly,
@ContractID BIGINT = NULL,
@CustomerID BIGINT = NULL,
@ComputedProcessThroughDate DATETIME
)
AS
BEGIN
SET NOCOUNT ON
CREATE TABLE #IntermediateTable  (
ContractId BIGINT
,SequenceNumber NVARCHAR(40)
,CustomerId BIGINT
,LegalEntityId BIGINT
,LeaseFinanceId BIGINT
,PayableId BIGINT
)
INSERT INTO #IntermediateTable(ContractId, SequenceNumber, CustomerId, LegalEntityId, LeaseFinanceId, PayableId)
SELECT lf.ContractId,con.SequenceNumber,lf.CustomerId,lf.LegalEntityId,lf.Id ,payable.Id
FROM LeaseFinances lf
INNER JOIN Contracts con ON lf.ContractId = con.Id
INNER JOIN Customers cus ON lf.CustomerId = cus.Id
INNER JOIN LegalEntities le ON lf.LegalEntityId = le.Id
INNER JOIN @LegalEntityIds LEId ON le.Id = LEId.LegalEntityId
INNER JOIN Payables payable ON lf.ContractId = payable.EntityId AND payable.EntityType = 'CT'
LEFT JOIN TransactionInstances trans ON lf.Id = trans.EntityId AND trans.EntityName = 'LeaseFinance'
WHERE (trans.Id IS NULL OR trans.Status != 'OnHold')
AND lf.IsCurrent = 1
AND lf.BookingStatus != 'Inactive'
AND lf.BookingStatus != 'Pending'
AND lf.ApprovalStatus != 'Inactive'
AND lf.BookingStatus != 'Terminated'
AND (con.SyndicationType != '_' AND con.SyndicationType != 'None')
AND (payable.SourceTable = 'SyndicatedAR' OR payable.SourceTable = 'IndirectAR')
AND payable.Status = 'Pending'
AND payable.DueDate <= @ComputedProcessThroughDate
AND (@ContractID IS NULL OR lf.ContractId = @ContractID)
AND (@CustomerID IS NULL OR lf.CustomerId = @CustomerID)

;WITH CTE_AllDRFromSystem
AS
(
SELECT drp.PayableId FROM #IntermediateTable IT
INNER JOIN DisbursementRequestPayables drp ON IT.PayableId = drp.PayableId
INNER JOIN DisbursementRequests dr ON drp.DisbursementRequestId = dr.Id
WHERE drp.IsActive = 1
AND dr.Status != 'Inactive'
)

DELETE FROM #IntermediateTable WHERE PayableId IN (SELECT PayableId FROM CTE_AllDRFromSystem)

SELECT 
	IT.ContractId, 
	SequenceNumber, 
	IT.CustomerId, 
	IT.LegalEntityId, 
	LeaseFinanceId,
	IT.PayableId,
	P.DueDate 'PayableDueDate',
	P.PayeeId,
	P.Amount_Amount 'PayableAmount',
	CC.ISO 'CurrencyCode',
	S.Id 'SundryId',
	S.PayableRemitToId 'SundryPayableRemitToId',
	S.Memo 'SundryMemo',
	S.CurrencyId 'SundryCurrencyId'
FROM #IntermediateTable IT
JOIN Payables P ON IT.PayableId = P.Id
LEFT JOIN Currencies C on P.CurrencyId = C.Id AND C.IsActive = 1
LEFT JOIN CurrencyCodes CC ON C.CurrencyCodeId = CC.Id
LEFT JOIN Sundries S ON P.Id = S.PayableId

DROP TABLE #IntermediateTable
END

GO
