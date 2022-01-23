SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SaveLeaseBlendedIncome]
(
@BlendedIncomeAmortDetails BlendedIncomeAmortDetail READONLY,
@LeaseFinanceId BIGINT,
@ContractModificationType NVARCHAR(max),
@ModificationId BIGINT,
@Currency NVARCHAR(3),
@CreatedById BIGINT,
@CreatedTime DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON
INSERT INTO BlendedIncomeSchedules
(
Income_Amount
,Income_Currency
,IncomeBalance_Amount
,IncomeBalance_Currency
,EffectiveYield
,EffectiveInterest_Amount
,EffectiveInterest_Currency
,IncomeDate
,IsAccounting
,IsSchedule
,IsNonAccrual
,PostDate
,AdjustmentEntry
,BlendedItemId
,ModificationType
,ModificationId
,LeaseFinanceId
,CreatedById
,CreatedTime
,IsRecomputed
)
SELECT
Income
,@Currency
,IncomeBalance
,@Currency
,0.0
,0.0
,@Currency
,IncomeDate
,IsAccounting
,IsSchedule
,IsNonAccrual
,PostDate
,IsAdjustmentEntry
,BlendedItemId
,@ContractModificationType
,@ModificationId
,@LeaseFinanceId
,@CreatedById
,@CreatedTime
,CAST(0 AS BIT)
FROM @BlendedIncomeAmortDetails
END

GO
