SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[UpdateAutoActionLogDetail](
      @AutoActionLogDetailId BIGINT
	, @EntityId BIGINT
	, @EntityName NVARCHAR(100)=NULL
	, @TransactionName NVARCHAR(100)= NULL
	, @WorkflowSource NVARCHAR(100)= NULL
	, @CommentId BIGINT
	, @IsNotificationOnly BIT
	)
AS
BEGIN

	IF @IsNotificationOnly = 1
		UPDATE AutoActionLogDetails SET IsSuccess = 1
		WHERE Id = @AutoActionLogDetailId
	
	IF @IsNotificationOnly = 0 AND (@TransactionName IS NOT NULL OR  @CommentId > 0)
		UPDATE AutoActionLogDetails
		SET IsSuccess = 1,
			WorkItemId = (CASE WHEN @TransactionName IS NOT NULL
						  THEN (SELECT TOP 1 wi.Id 
						        FROM WorkItems wi 
					            JOIN TransactionInstances txn ON wi.TransactionInstanceId = txn.Id 
					            WHERE txn.TransactionName = @TransactionName 
								  AND txn.EntityName = @EntityName 
								  AND ((@WorkflowSource IS NOT NULL AND txn.WorkflowSource = @WorkflowSource) OR (@WorkflowSource IS NULL AND txn.WorkflowSource IS NULL))
								  AND txn.EntityId = @EntityId 
								  AND txn.IsFromAutoAction = 1
								  AND txn.Status = 'Active' 
								  AND wi.Status IN ('Unassigned','Assigned')
						        ORDER BY wi.Id DESC)
							    ELSE NULL END),
			CommentId = (CASE WHEN @CommentId > 0 THEN @CommentId ELSE NULL END)
		WHERE Id = @AutoActionLogDetailId
	
END

GO
