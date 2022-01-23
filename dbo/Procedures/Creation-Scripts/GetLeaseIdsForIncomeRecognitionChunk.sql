SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[GetLeaseIdsForIncomeRecognitionChunk] (
	@BatchSize INT,
	@UpdatedById BIGINT,
	@TaskChunkServiceInstanceId BIGINT = NULL,
	@UpdatedTime DATETIMEOFFSET,
	@JobStepInstanceId BIGINT,
	@ConsiderFiscalCalendar BIT
	)
AS
BEGIN
	IF (@ConsiderFiscalCalendar = 1)
	BEGIN
		UPDATE TOP (@BatchSize) LeaseIncomeRecognitionJob_Extracts
		SET TaskChunkServiceInstanceId = @TaskChunkServiceInstanceId,
		IsSubmitted = 1
		OUTPUT Deleted.LeaseFinanceId as LeaseId, Deleted.AssetCount, Deleted.PostDate as PostDate, Deleted.ProcessThroughDate as ProcessThroughDate
		WHERE JobStepInstanceId = @JobStepInstanceId
		AND IsSubmitted = 0
		AND PostDate = (SELECT TOP 1 PostDate FROM LeaseIncomeRecognitionJob_Extracts WHERE IsSubmitted = 0 AND JobStepInstanceId = @JobStepInstanceId)
		AND ProcessThroughDate = (SELECT TOP 1 ProcessThroughDate FROM LeaseIncomeRecognitionJob_Extracts WHERE IsSubmitted = 0 AND JobStepInstanceId = @JobStepInstanceId)
	END
	ELSE
	BEGIN
		UPDATE TOP (@BatchSize) LeaseIncomeRecognitionJob_Extracts
		SET TaskChunkServiceInstanceId = @TaskChunkServiceInstanceId,
			IsSubmitted = 1
		OUTPUT Deleted.LeaseFinanceId as LeaseId, Deleted.AssetCount, Deleted.PostDate as PostDate, Deleted.ProcessThroughDate as ProcessThroughDate
		WHERE JobStepInstanceId = @JobStepInstanceId AND IsSubmitted = 0 
	END
END

GO
