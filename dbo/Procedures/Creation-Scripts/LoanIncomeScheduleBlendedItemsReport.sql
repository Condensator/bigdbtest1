SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[LoanIncomeScheduleBlendedItemsReport]
(
@ContractId BigInt,
@UserId BigInt
)
AS
BEGIN
SELECT * FROM LoanBlendedIncomeSummaryForReports WHERE ContractId = @ContractId AND CreatedById = @UserId
Delete From LoanBlendedIncomeSummaryForReports WHERE ContractId = @ContractId AND CreatedById = @UserId
END

GO
