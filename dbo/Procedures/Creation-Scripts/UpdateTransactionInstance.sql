SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[UpdateTransactionInstance]
(
@CurrentEntityId BIGINT,
@OldEntityId BIGINT,
@EntityName NVARCHAR(20),
@TransactionStatusActive NVARCHAR(30)
)
AS
BEGIN
SET NOCOUNT ON
UPDATE TransactionInstances
SET EntityId = @CurrentEntityId
WHERE EntityId = @OldEntityId
AND EntityName = @EntityName
AND Status = @TransactionStatusActive
END

GO
