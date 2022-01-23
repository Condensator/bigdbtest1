SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[UpdateTransactionInstanceForPayoff]
(
@CurrentLeaseFinanceId BIGINT,
@OldLeaseFinanceId BIGINT,
@LeaseFinance NVARCHAR(20),
@TransactionStatusActive NVARCHAR(30)
)
AS
BEGIN
SET NOCOUNT ON
UPDATE TransactionInstances
SET EntityId = @CurrentLeaseFinanceId
WHERE EntityId = @OldLeaseFinanceId
AND EntityName = @LeaseFinance
AND Status = @TransactionStatusActive
END

GO
