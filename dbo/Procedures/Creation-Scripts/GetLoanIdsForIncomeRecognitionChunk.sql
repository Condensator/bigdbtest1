SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[GetLoanIdsForIncomeRecognitionChunk] (
	@BatchSize INT,
	@UpdatedById BIGINT,
	@TaskChunkServiceInstanceId BIGINT = NULL,
	@ConsiderFiscalCalendar BIT,
	@UpdatedTime DATETIMEOFFSET,
	@JobStepInstanceId BIGINT
	)
AS
BEGIN
	IF (@ConsiderFiscalCalendar = 1)
	BEGIN
		UPDATE TOP (@BatchSize) [LoanIncomeRecognitionJobExtracts]
		SET TaskChunkServiceInstanceId = @TaskChunkServiceInstanceId,
		UpdatedById = @UpdatedById,
		UpdatedTime = @UpdatedTime,
		IsSubmitted = 1
		OUTPUT Deleted.LoanFinanceId as Id, Deleted.PostDate as PostDate, Deleted.ProcessThroughDate as ProcessThroughDate
		WHERE JobStepInstanceId = @JobStepInstanceId
		AND IsSubmitted = 0
		AND PostDate = (SELECT TOP 1 PostDate FROM LoanIncomeRecognitionJobExtracts WHERE IsSubmitted = 0 AND JobStepInstanceId = @JobStepInstanceId)
		AND ProcessThroughDate = (SELECT TOP 1 ProcessThroughDate FROM LoanIncomeRecognitionJobExtracts WHERE IsSubmitted = 0 AND JobStepInstanceId = @JobStepInstanceId)
	END
	ELSE
	BEGIN
		UPDATE TOP (@BatchSize) [LoanIncomeRecognitionJobExtracts]
		SET TaskChunkServiceInstanceId = @TaskChunkServiceInstanceId,
			UpdatedById = @UpdatedById,
			UpdatedTime = @UpdatedTime,
			IsSubmitted = 1
		OUTPUT Deleted.LoanFinanceId AS Id,
			Deleted.PostDate AS PostDate,
			Deleted.ProcessThroughDate AS ProcessThroughDate
		WHERE JobStepInstanceId = @JobStepInstanceId AND IsSubmitted = 0
	END
END

GO
