SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[AssignQueueToContracts]
(
	@PortfolioId BIGINT,
	@JobStepInstanceId BIGINT
)
AS
BEGIN
	SELECT 
		 Id
		,AcrossQueue
		,RuleExpression
		,Row_Number() OVER (ORDER BY Id) as RowNumber
	INTO #CollectionQueue
	FROM CollectionQueues
	WHERE IsActive = 1 AND
	PortfolioId = @PortfolioId;

	DECLARE @LastRowNumber BIGINT = (SELECT IsNull(Max(RowNumber), 0) FROM #CollectionQueue)
	DECLARE @CurrentRowNumber BIGINT = 1
	DECLARE @Query NVARCHAR(Max);
	DECLARE @QueueId BIGINT;
	DECLARE @AcrossQueue BIT;

	CREATE TABLE #ContractsQualifiedFromQueue (ContractId BIGINT)
	
	WHILE (@LastRowNumber >= @CurrentRowNumber)
	BEGIN
		SELECT 
			@Query = RuleExpression, @QueueId = Id, @AcrossQueue = AcrossQueue
		FROM #CollectionQueue
		WHERE RowNumber = @CurrentRowNumber

		INSERT INTO #ContractsQualifiedFromQueue (ContractId)
		EXEC SP_EXECUTESQL @Query
	
		UPDATE CollectionsJobExtracts 
			SET AllocatedQueueId = @QueueId, AcrossQueue = @AcrossQueue
		FROM CollectionsJobExtracts 
			INNER JOIN #ContractsQualifiedFromQueue ON CollectionsJobExtracts.ContractId = #ContractsQualifiedFromQueue.ContractId
		WHERE CollectionsJobExtracts.JobStepInstanceId = @JobStepInstanceId

		SET @CurrentRowNumber = @CurrentRowNumber + 1

		TRUNCATE TABLE #ContractsQualifiedFromQueue
	END;


	DROP TABLE #ContractsQualifiedFromQueue
	DROP TABLE #CollectionQueue
END

GO
