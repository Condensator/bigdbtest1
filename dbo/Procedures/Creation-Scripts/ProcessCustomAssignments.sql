SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[ProcessCustomAssignments]
(
	@JobStepInstanceId BIGINT, 
	@CustomAssignmentMethod NVARCHAR(6),
	@UserApproved NVARCHAR(8)
)
AS
BEGIN

	CREATE TABLE #ExpressionCollectors 
	(		
		Id BIGINT NOT NULL IDENTITY(1,1) PRIMARY KEY,
		CustomerId BIGINT NULL, 
		PrimaryCollectorId BIGINT NULL
	)

	SELECT
			*,Row_Number() OVER (ORDER BY Id) as RowNumber
		INTO #CustomQueues
		FROM
		(
			SELECT 	
				DISTINCT
				CollectionQueues.Id,
				CollectionQueues.Name,
				CustomerAssignmentRuleExpression
			FROM 
				CollectionsJobExtracts
			INNER JOIN CollectionQueues 
				ON CollectionsJobExtracts.AllocatedQueueId = CollectionQueues.Id
			WHERE 
				CollectionsJobExtracts.JobStepInstanceId = @JobStepInstanceId
				AND CollectionQueues.AssignmentMethod = @CustomAssignmentMethod	
		) AS DistinctCustomQueues;


	DECLARE @LastRowNumber BIGINT = (SELECT IsNull(Max(RowNumber), 0) FROM #CustomQueues)
	DECLARE @CurrentRowNumber BIGINT = 1
	DECLARE @Query NVARCHAR(Max);
	DECLARE @QueueId BIGINT;
	DECLARE @QueueName NVARCHAR(40);

	WHILE (@CurrentRowNumber <= @LastRowNumber)
	BEGIN
	
		SELECT 
			@Query = CustomerAssignmentRuleExpression, 
			@QueueId = Id,
			@QueueName = Name 
		FROM #CustomQueues
		WHERE RowNumber = @CurrentRowNumber

		INSERT INTO #ExpressionCollectors (CustomerId, PrimaryCollectorId)
			EXEC SP_EXECUTESQL @Query

		SELECT 
				CustomerId,
				PrimaryCollectorId	
			INTO #LatestAssignments
			FROM
			(
				SELECT 
					CustomerId,
					PrimaryCollectorId,
					Row_Number() OVER (PARTITION BY CustomerId ORDER BY #ExpressionCollectors.Id desc) as RowNumber
				FROM #ExpressionCollectors
				INNER JOIN Users
					ON Users.Id = #ExpressionCollectors.PrimaryCollectorId
				WHERE Users.ApprovalStatus = @UserApproved
					AND CustomerId IS NOT NULL 
					AND PrimaryCollectorId IS NOT NULL			
			) AS ActiveCollectors
			WHERE RowNumber = 1


		UPDATE CollectionsJobExtracts
				SET PrimaryCollectorId = #LatestAssignments.PrimaryCollectorId
			FROM 
				CollectionsJobExtracts
			INNER JOIN #LatestAssignments 
				ON #LatestAssignments.CustomerId = CollectionsJobExtracts.CustomerId
			WHERE 
				CollectionsJobExtracts.JobStepInstanceId = @JobStepInstanceId AND
				CollectionsJobExtracts.AllocatedQueueId = @QueueId 	AND
				CollectionsJobExtracts.PrimaryCollectorId IS NULL; -- To Ignore Across Queue collectors, existing worklists
		
	
	SET @CurrentRowNumber = @CurrentRowNumber + 1;

	DROP TABLE #LatestAssignments;
	TRUNCATE TABLE #ExpressionCollectors;

	END;

	DROP TABLE #CustomQueues ;
	DROP TABLE #ExpressionCollectors;

END

GO
