SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[LoanIncomeScheduleIncomeReport]
(
@ContractId BigInt,
@UserId BigInt
)
AS
BEGIN
SELECT * FROM LoanIncomeSummaryForReports WHERE ContractId = @ContractId AND CreatedById = @UserId ORDER BY LoanIncomeSummaryForReports.IncomeDate
Delete From LoanIncomeSummaryForReports Where ContractId = @ContractId AND CreatedById = @UserId
END

GO
