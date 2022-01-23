SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[UpdateCustomerCollectionStatus] 
(	
	 @CustomerId BIGINT	
	,@ManualCollectionStatusAssignment NVARCHAR(9)
	,@PortfolioId BIGINT
	,@UserId BIGINT
	,@ServerTimeStamp DATETIMEOFFSET
)
AS
BEGIN
	SET NOCOUNT ON;

	CREATE TABLE #ExpressionCustomers (CustomerId BIGINT NULL)

	CREATE TABLE #LatestAssignments
	(
		CustomerId BIGINT,
		CollectionStatusId BIGINT,
		AssignmentMethod NVARCHAR(9)
	)

	SELECT 
			Id AS CollectionStatusId,
			RuleExpression,
			AssignmentMethod,
			Row_Number() OVER (ORDER BY Id) AS RowNumber
		INTO #CollectionStatus
		FROM dbo.CollectionStatus
			WHERE IsActive = 1
				  AND AssignmentMethod <> @ManualCollectionStatusAssignment
				  AND PortfolioId = @PortfolioId
			ORDER BY Id

	
	DECLARE @CurrentRowNumber BIGINT = 1;
	DECLARE @CollectionStatusId BIGINT;
	DECLARE @AssignmentMethod NVARCHAR(9);
	DECLARE @LastRowNumber BIGINT = (SELECT IsNull(Max(RowNumber), 0) FROM #CollectionStatus);

	WHILE (@LastRowNumber >= @CurrentRowNumber)
	BEGIN

		DECLARE @Query NVARCHAR(Max);

		SELECT  
				@CollectionStatusId = CollectionStatusId,
				@Query = RuleExpression,
				@AssignmentMethod = AssignmentMethod
			FROM #CollectionStatus 
			WHERE RowNumber = @CurrentRowNumber

		TRUNCATE TABLE #ExpressionCustomers

		INSERT INTO #ExpressionCustomers (CustomerId) EXEC SP_EXECUTESQL @Query

		MERGE #LatestAssignments
				USING #ExpressionCustomers ON #LatestAssignments.CustomerId = #ExpressionCustomers.CustomerId
			WHEN MATCHED THEN
				UPDATE SET 
						CollectionStatusId = @CollectionStatusId,
						AssignmentMethod = @AssignmentMethod
			WHEN NOT MATCHED BY TARGET AND #ExpressionCustomers.CustomerId IS NOT NULL THEN 
				INSERT
				(
					CustomerId,
					CollectionStatusId,
					AssignmentMethod
				)
				VALUES
				(
					#ExpressionCustomers.CustomerId,
					@CollectionStatusId,
					@AssignmentMethod
				);

			
		SET @CurrentRowNumber = @CurrentRowNumber + 1;

	END	

	SELECT 
			CustomerId, 
			#LatestAssignments.CollectionStatusId, 
			AssignmentMethod
		INTO #UpdatedCustomers
		FROM Customers
			INNER JOIN #LatestAssignments ON Customers.Id =  #LatestAssignments.CustomerId
			INNER JOIN Parties ON Customers.Id = Parties.Id
		WHERE 
			(Customers.CollectionStatusId IS NULL OR Customers.CollectionStatusId != #LatestAssignments.CollectionStatusId)  
			AND Parties.PortfolioId = @PortfolioId
			AND (@CustomerId = 0 OR Customers.Id = @CustomerId)


	UPDATE Customers
			SET Customers.CollectionStatusId = #UpdatedCustomers.CollectionStatusId,
				UpdatedById = @UserId,
				UpdatedTime = @ServerTimeStamp
		FROM Customers
			INNER JOIN #UpdatedCustomers ON Customers.Id =  #UpdatedCustomers.CustomerId
		

	INSERT INTO CollectionCustomerStatusHistories 
		(
			 AssignmentMethod
			,AssignmentDate
			,AssignedByUserId
			,CreatedById
			,CreatedTime
			,CustomerId
			,CollectionStatusId
		)
	SELECT 
		 AssignmentMethod
		,@ServerTimeStamp
		,@UserId
		,@UserId
		,@ServerTimeStamp
		,CustomerId
		,CollectionStatusId
	FROM #UpdatedCustomers
	

	-- Customers with no new status found
	UPDATE Customers
			SET Customers.CollectionStatusId = NULL,
				UpdatedById = @UserId,
				UpdatedTime = @ServerTimeStamp
		FROM Customers
			INNER JOIN Parties ON Customers.Id = Parties.Id
			INNER JOIN CollectionStatus ON Customers.CollectionStatusId = CollectionStatus.Id
			LEFT JOIN #LatestAssignments ON Customers.Id = #LatestAssignments.CustomerId
		WHERE 
			#LatestAssignments.CustomerId IS NULL 
			AND CollectionStatus.AssignmentMethod <> @ManualCollectionStatusAssignment
			AND Parties.PortfolioId = @PortfolioId
			AND (@CustomerId = 0 OR Customers.Id = @CustomerId)

	DROP TABLE #ExpressionCustomers
	DROP TABLE #LatestAssignments
	DROP TABLE #UpdatedCustomers
	DROP TABLE #CollectionStatus

END

GO
