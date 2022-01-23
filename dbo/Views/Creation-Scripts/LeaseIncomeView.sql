SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[LeaseIncomeView] AS
SELECT
C.SequenceNumber,LF.ContractId,
LF.Id LeaseFinanceId,
LF.IsCurrent IsCurrentLeaseFinance,
LI.Id LeaseIncomeScheduleId,
LI.LeaseModificationType,
LI.IncomeDate,
LI.IncomeType,
LI.Payment_Amount Payment,
LI.BeginNetBookValue_Amount BeginNetBookValue,
LI.IncomeAccrued_Amount IncomeAccrued,
LI.Income_Amount Income,
LI.IncomeBalance_Amount IncomeBalance,
LI.EndNetBookValue_Amount EndNetBookValue,
LI.ResidualIncome_Amount ResidualIncome,
LI.ResidualIncomeBalance_Amount ResidualIncomeBalance,
LI.RentalIncome_Amount RentalIncome,
LI.DeferredRentalIncome_Amount DeferredRentalIncome,
LI.OperatingBeginNetBookValue_Amount OperatingBeginNetBookValue,
LI.Depreciation_Amount Depreciation,
LI.OperatingEndNetBookValue_Amount OperatingEndNetBookValue,
LI.IsGLPosted,
LI.PostDate,
LI.IsAccounting,
LI.IsSchedule,
LI.AdjustmentEntry,
LI.IsLessorOwned,
LI.IsNonAccrual,
LI.AccountingTreatment,
LI.LeaseModificationID
FROM LeaseIncomeSchedules LI WITH (NOLOCK)
JOIN LeaseFinances LF WITH (NOLOCK) ON LI.LeaseFinanceId = LF.Id
JOIN LeaseFinanceDetails LFD WITH (NOLOCK) ON LF.Id = LFD.Id
JOIN Contracts C ON LF.ContractId = C.Id

GO
