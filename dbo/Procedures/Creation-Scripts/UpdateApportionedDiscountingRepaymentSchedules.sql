SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[UpdateApportionedDiscountingRepaymentSchedules]
(
@RepaymentSchedulesToBeUpdated RepaymentSchedulesToBeUpdated READONLY
,@UpdatedById BIGINT
,@UpdatedTime DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
UPDATE DRS
SET	DRS.EffectiveExpenseBalance_Amount = RS.EffectiveExpenseBalance,
DRS.EffectivePrincipalBalance_Amount = RS.EffectivePrincipalBalance,
DRS.PrincipalBookBalance_Amount = RS.PrincipalBookBalance,
DRS.ExpenseBookBalance_Amount = RS.ExpenseBookBalance,
DRS.IsApportioned = RS.IsApportioned,
DRS.UpdatedById = @UpdatedById,
DRS.UpdatedTime = @UpdatedTime
FROM dbo.DiscountingRepaymentSchedules DRS
JOIN @RepaymentSchedulesToBeUpdated RS ON DRS.Id = RS.RepaymentScheduleId
END

GO
