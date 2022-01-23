SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[UpdateTransactionInstanceForContract]
(
@CurrentFinanceId BIGINT,
@OldFinanceId BIGINT,
@EntityName NVARCHAR(20),
@TransactionStatusActive NVARCHAR(30)
)
AS
BEGIN
SET NOCOUNT ON
UPDATE TransactionInstances
SET EntityId = @CurrentFinanceId
WHERE EntityId = @OldFinanceId
AND EntityName = @EntityName
AND Status = @TransactionStatusActive
END

GO
