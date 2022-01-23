SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

Create PROCEDURE [dbo].[GetLoansforIncomeAmortChunk]
(
@BatchSize INT,
@UpdatedById BIGINT,
@UpdatedTime DATETIMEOFFSET,
@TaskChunkServiceInstanceId BIGINT = NULL,
@JobInstanceId BIGINT
) AS
BEGIN
UPDATE TOP (@BatchSize) LoanIncomeAmortJobExtracts
SET TaskChunkServiceInstanceId = @TaskChunkServiceInstanceId,
UpdatedById = @UpdatedById,
UpdatedTime = @UpdatedTime,
IsSubmitted = 1
OUTPUT Deleted.LoanFinanceId
WHERE TaskChunkServiceInstanceId IS NULL AND IsSubmitted = 0
AND JobInstanceId = @JobInstanceId
END

GO
