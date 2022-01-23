SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[GetReceivablesForWithHoldingTaxAssessment]
(
@BatchSize INT,
@UpdatedById BIGINT,
@TaskChunkServiceInstanceId BIGINT = NULL,
@UpdatedTime DATETIMEOFFSET,
@JobStepInstanceId BIGINT
) AS
BEGIN

;WITH CTE_EntitiesForCurrentBatch AS (
	SELECT 
		 TOP (@BatchSize) EntityId
		,EntityType
	FROM 
		WithHoldingTaxExtracts (UPDLOCK)
	WHERE 
		TaskChunkServiceInstanceId IS NULL 
		AND IsSubmitted = 0 
		AND JobStepInstanceId = @JobStepInstanceId
	GROUP BY 
		 EntityId
		,EntityType
)
UPDATE WithHoldingTaxExtracts
SET 
	TaskChunkServiceInstanceId = @TaskChunkServiceInstanceId,
	UpdatedById = @UpdatedById,
	UpdatedTime = @UpdatedTime,
	IsSubmitted = 1
OUTPUT Deleted.ReceivableId [Id]
FROM 
	WithHoldingTaxExtracts
JOIN CTE_EntitiesForCurrentBatch 
	ON WithHoldingTaxExtracts.EntityId = CTE_EntitiesForCurrentBatch.EntityId
	AND WithHoldingTaxExtracts.EntityType = CTE_EntitiesForCurrentBatch.EntityType
WHERE 
	TaskChunkServiceInstanceId IS NULL 
	AND IsSubmitted = 0
	AND JobStepInstanceId = @JobStepInstanceId
	AND IsSubmitted = 0

END

GO
