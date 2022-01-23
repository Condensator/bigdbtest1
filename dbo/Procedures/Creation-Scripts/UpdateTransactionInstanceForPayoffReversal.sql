SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[UpdateTransactionInstanceForPayoffReversal]
(
@CurrentLeaseFinanceId BIGINT,
@OldLeaseFinanceId BIGINT,
@LeaseFinance NVARCHAR(20),
@CurrentUserId BIGINT,
@CurrentTime DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON
UPDATE TransactionInstances
SET EntityId = @OldLeaseFinanceId , UpdatedById = @CurrentUserId, UpdatedTime = @CurrentTime
WHERE EntityId = @CurrentLeaseFinanceId
AND EntityName = @LeaseFinance
UPDATE LeaseInsuranceRequirements
SET IsActive = 0 , UpdatedById = @CurrentUserId, UpdatedTime = @CurrentTime
WHERE LeaseFinanceId = @CurrentLeaseFinanceId
END

GO
