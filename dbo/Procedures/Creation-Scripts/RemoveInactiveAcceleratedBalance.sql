SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[RemoveInactiveAcceleratedBalance]
(
@AcceleratedBalanceDetailId BIGINT
)
As
SET NOCOUNT ON
IF  @AcceleratedBalanceDetailId > 0
BEGIN
DELETE FROM AcceleratedBalanceEstimatedPropertyTaxes WHERE IsActive = 0 AND AcceleratedBalanceEstimatedPropertyTaxes.AcceleratedBalanceDetailId = @AcceleratedBalanceDetailId
DELETE FROM AcceleratedBalanceExpenses WHERE IsActive = 0 AND AcceleratedBalanceExpenses.AcceleratedBalanceDetailId = @AcceleratedBalanceDetailId
DELETE FROM AcceleratedBalanceCredits WHERE IsActive = 0 AND AcceleratedBalanceCredits.AcceleratedBalanceDetailId = @AcceleratedBalanceDetailId
DELETE FROM AcceleratedBalanceInterestAccrualDetails WHERE IsActive = 0 AND AcceleratedBalanceInterestAccrualDetails.AcceleratedBalanceDetailId = @AcceleratedBalanceDetailId
DELETE FROM AcceleratedBalancePIHistories WHERE IsActive = 0 AND AcceleratedBalancePIHistories.AcceleratedBalanceDetailId = @AcceleratedBalanceDetailId
END

GO
