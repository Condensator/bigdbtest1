SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[LeaseBlendedIncomeView] AS
SELECT
C.SequenceNumber,LF.ContractId,
LF.Id LeaseFinanceId,
LF.IsCurrent IsCurrentLeaseFinance,
LI.Id LeaseIncomeScheduleId,
LI.IncomeDate,
LI.IncomeType,
LI.AdjustmentEntry,
BI.Name BlendedItem,
BI.Type [Type],
BIC.Name Code,
BIS.Income_Amount BlendedIncome,
BIS.IncomeBalance_Amount BlendedIncomeBalance,
BIS.IsAccounting BIsAccounting,
BIS.IsSchedule BIsSchedule,
BIS.EffectiveYield,
BIS.EffectiveInterest_Amount EffectiveInterest,
BIS.PostDate BPostDate,
BIS.ReversalPostDate,
BIS.ModificationType BModificationType,
BIS.ModificationId BModificationId,
BIS.IsNonAccrual BIsNonAccrual,
BIS.BlendedItemId,
BIS.AdjustmentEntry BAdjustmentEntry
FROM LeaseIncomeSchedules LI WITH (NOLOCK)
JOIN LeaseFinances LF WITH (NOLOCK) ON LI.LeaseFinanceId = LF.Id
JOIN LeaseFinanceDetails LFD WITH (NOLOCK) ON LF.Id = LFD.Id
JOIN Contracts C WITH (NOLOCK) ON LF.ContractId = C.Id
LEFT JOIN BlendedIncomeSchedules BIS WITH (NOLOCK) ON LF.Id = BIS.LeaseFinanceId And LI.IncomeDate = BIS.IncomeDate
LEFT JOIN BlendedItems BI WITH (NOLOCK) ON BIS.BlendedItemId = BI.Id
LEFT JOIN BlendedItemCodes BIC WITH (NOLOCK) ON BI.BlendedItemCodeId = BIC.Id

GO
