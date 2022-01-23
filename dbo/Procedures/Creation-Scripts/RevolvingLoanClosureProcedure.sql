SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[RevolvingLoanClosureProcedure]
(
@AllLoans BIT,
@ContractId BIGINT,
@ProcessThroughDate DATE,
@UpdatedById BIGINT,
@UpdatedTime DATETIMEOFFSET
)
AS
BEGIN
Declare @LoanFinanceID AS BIGINT
Declare @LastIncomeEndNBV AS DECIMAL
SET NOCOUNT ON;
IF @AllLoans =0
BEGIN
SELECT TOP 1 @LoanFinanceID =  Id FROM LoanFinances WHERE ContractId = @ContractId and IsCurrent = 1 ;
UPDATE LoanFinances SET Status='FullyPaidOff',UpdatedById=@UpdatedById,UpdatedTime=@UpdatedTime WHERE Id=@LoanFinanceID
UPDATE Contracts SET Status='FullyPaidOff',UpdatedById=@UpdatedById,UpdatedTime=@UpdatedTime Where Id=@ContractId
END
ELSE
BEGIN
With LoanFinanceAndMaximumIncomeDate as
(
SELECT C.Id ContractId, LIS.LoanFinanceId , MAX(IncomeDate) IncomeDate FROM Contracts C
JOIN LoanFinances LF on C.Id = LF.ContractId
JOIN LoanIncomeSchedules  LIS on LF.Id = LIS.LoanFinanceId
WHERE LIS.IsAccounting = 1
AND LF.IsRevolvingLoan = 1
GROUP BY LIS.LoanFinanceId , C.Id
),
ContractsWithZeroEndBalance as
(
SELECT LF.ContractId , LF.LoanFinanceId FROM LoanIncomeSchedules LIS
JOIN LoanFinanceAndMaximumIncomeDate  LF on LIS.IncomeDate = LF.IncomeDate AND LIS.LoanFinanceId = LF.LoanFinanceId
WHERE LIS.IsAccounting = 1
AND LIS.EndNetBookValue_Amount = 0.00
),
ContractsToChangeStatus as
(
SELECT CZ.ContractId FROM Contracts C
JOIN ContractsWithZeroEndBalance CZ on C.Id = CZ.ContractId
JOIN CreditApprovedStructures CA on C.CreditApprovedStructureId = CA.Id
JOIN CreditDecisions CD on CA.CreditProfileId = CD.CreditProfileId
Where CD.IsActive = 1
AND CD.DecisionStatus = 'Approved'
AND CD.ExpiryDate <= @ProcessThroughDate
)
Select ContractId Into #ContractIds from ContractsToChangeStatus
UPDATE LoanFinances SET Status='FullyPaidOff',UpdatedById=@UpdatedById,UpdatedTime=@UpdatedTime
WHERE ContractId in (Select Id from #ContractIds) AND IsCurrent = 1
UPDATE Contracts SET Status='FullyPaidOff',UpdatedById=@UpdatedById,UpdatedTime=@UpdatedTime
Where Id in (Select Id from #ContractIds)
END
SET NOCOUNT OFF;
IF OBJECT_ID('#ContractIds') IS NOT NULL
BEGIN
DROP TABLE #ContractIds
END
END

GO
