SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[UpdateTransactionInstanceForPaydown]
(
@CurrentLoanFinanceId BIGINT,
@OldLoanFinanceId BIGINT,
@LoanFinance NVARCHAR(20)
)
AS
BEGIN
SET NOCOUNT ON
UPDATE
TransactionInstances
SET
EntityId=@CurrentLoanFinanceId
WHERE
Id IN (SELECT Id FROM TransactionInstances WHERE EntityId=@OldLoanFinanceId AND EntityName=@LoanFinance)
END

GO
