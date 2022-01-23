SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[LeaseFloatRateIncomeView] AS
SELECT
C.SequenceNumber,LF.ContractId,
LF.Id LeaseFinanceId,
LF.IsCurrent IsCurrentLeaseFinance,
LI.Id LeaseIncomeScheduleId,
LFI.IncomeDate,
LFI.CustomerIncomeAccruedAmount_Amount FRCustomerIncomeAccruedAmount,
LFI.CustomerIncomeAmount_Amount FRCustomerIncome,
LFI.CustomerReceivableAmount_Amount FRCustomerReceivableAmount,
LFI.InterestRate FRInterestRate,
LFI.IsAccounting FRIsAccounting,
LFI.IsScheduled FRIsSchedule,
LFI.IsGLPosted FRIsGLPosted,
LFI.IsLessorOwned FRIsLessorOwned,
LFI.IsNonAccrual FRIsNonAccrual,
LFI.ModificationId FRModificationId,
LFI.ModificationType FRModificationType
FROM LeaseIncomeSchedules LI
JOIN LeaseFinances LF ON LI.LeaseFinanceId = LF.Id
JOIN LeaseFinanceDetails LFD ON LF.Id = LFD.Id
JOIN Contracts C ON LF.ContractId = C.Id
LEFT JOIN LeaseFloatRateIncomes LFI ON LF.Id = LFI.LeaseFinanceId
And LI.IncomeDate = LFI.IncomeDate

GO
