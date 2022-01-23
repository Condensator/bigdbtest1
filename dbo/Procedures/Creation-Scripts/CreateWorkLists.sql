SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[CreateWorkLists]
(
	@JobStepInstanceId BIGINT,
	@PortfolioId BIGINT,
	@CollectionWorkListStatusOpen NVARCHAR(11),
	@CollectionWorkListStatusClosed NVARCHAR(11),
	@UnknownEnumValue NVARCHAR(29),
	@UserId BIGINT,
	@ServerTimeStamp DATETIMEOFFSET
)
AS
BEGIN
	-- Add to existing worklist
 
	INSERT INTO CollectionWorkListContractDetails
	(
			IsWorkCompleted
           ,CreatedById
           ,CreatedTime           
           ,ContractId
           ,CollectionWorkListId
           ,CompletionReason
	)
     SELECT 
		 0
        ,@UserId
        ,@ServerTimeStamp
        ,ContractId
        ,PreviousWorkListId
        ,@UnknownEnumValue
	FROM
		CollectionsJobExtracts
	INNER JOIN Currencies
		ON CollectionsJobExtracts.CurrencyId = Currencies.Id
	INNER JOIN CurrencyCodes	
		ON Currencies.CurrencyCodeId = CurrencyCodes.Id
	WHERE
		CollectionsJobExtracts.JobStepInstanceId = @JobStepInstanceId AND
		CollectionsJobExtracts.IsWorkListIdentified = 1 AND
		CollectionsJobExtracts.IsWorkListCreated = 0


	UPDATE CollectionWorkLists
		SET Status = @CollectionWorkListStatusOpen, UpdatedById = @UserId, UpdatedTime = @ServerTimeStamp
	FROM CollectionWorkLists
		INNER JOIN CollectionsJobExtracts
			ON CollectionWorkLists.Id = CollectionsJobExtracts.PreviousWorkListId
	WHERE
		CollectionsJobExtracts.JobStepInstanceId = @JobStepInstanceId AND
		CollectionsJobExtracts.IsWorkListIdentified = 1 AND
		CollectionsJobExtracts.IsWorkListCreated = 0 AND 
		CollectionWorkLists.Status <> @CollectionWorkListStatusOpen
	

	UPDATE CollectionWorkLists 
			SET PrimaryCollectorId = CollectionsJobExtracts.PrimaryCollectorId,
				UpdatedById = @UserId,
				UpdatedTime = @ServerTimeStamp
		FROM CollectionWorkLists
			INNER JOIN CollectionsJobExtracts ON CollectionsJobExtracts.PreviousWorkListId = CollectionWorkLists.Id
		WHERE CollectionWorkLists.PrimaryCollectorId IS NULL
			AND CollectionsJobExtracts.PrimaryCollectorId IS NOT NULL
			AND IsWorkListIdentified = 1
			AND CollectionWorkLists.Status <> @CollectionWorkListStatusClosed

		
	SELECT DISTINCT 
		CollectionsJobExtracts.CustomerId, CollectionsJobExtracts.PrimaryCollectorId, CollectionsJobExtracts.AllocatedQueueId, CollectionQueues.AssignmentMethod, CollectionsJobExtracts.CurrencyId, CollectionsJobExtracts.RemitToId, CollectionsJobExtracts.BusinessUnitId, CurrencyCodes.ISO 
	INTO #NewWorkListsToCreate
	FROM
		CollectionsJobExtracts
	INNER JOIN CollectionQueues
		ON CollectionsJobExtracts.AllocatedQueueId = CollectionQueues.Id
	INNER JOIN Currencies
		ON CollectionsJobExtracts.CurrencyId = Currencies.Id
	INNER JOIN CurrencyCodes	
		ON Currencies.CurrencyCodeId = CurrencyCodes.Id
	WHERE
		JobStepInstanceId = @JobStepInstanceId
		AND IsWorkListIdentified = 0
		AND AllocatedQueueId IS NOT NULL 

	CREATE TABLE #InsertedRecords
	(
		Id BIGINT,
		CustomerId BIGINT,
		CollectionQueueId BIGINT,
		CurrencyId BIGINT,
		PrimaryCollectorId BIGINT,
		RemitToId BIGINT NULL,
		BusinessUnitId BIGINT
	)

	INSERT INTO CollectionWorkLists
	(
		 Status
		,AssignmentMethod
		,CreatedById
		,CreatedTime
		,CustomerId
		,PrimaryCollectorId
		,PortfolioId
		,CollectionQueueId
		,CurrencyId
		,RemitToId
		,BusinessUnitId
		,FlagAsWorked
	)
	OUTPUT inserted.Id, inserted.CustomerId, inserted.CollectionQueueId, inserted.CurrencyId, inserted.PrimaryCollectorId, inserted.RemitToId, inserted.BusinessUnitId 
	INTO #InsertedRecords
	SELECT
		@CollectionWorkListStatusOpen
		,AssignmentMethod
		,@UserId
        ,@ServerTimeStamp
		,CustomerId
		,PrimaryCollectorId
		,@PortfolioId
		,AllocatedQueueId
		,CurrencyId 	
		,RemitToId
		,BusinessUnitId
		,0
	FROM #NewWorkListsToCreate
	
	INSERT INTO CollectionWorkListContractDetails
	(
			IsWorkCompleted
           ,CreatedById
           ,CreatedTime
           ,ContractId
           ,CollectionWorkListId
           ,CompletionReason
	)
     SELECT 
		 0
        ,@UserId
        ,@ServerTimeStamp
        ,ContractId
        ,#InsertedRecords.Id
        ,@UnknownEnumValue
	FROM
		CollectionsJobExtracts
	INNER JOIN Currencies
		ON CollectionsJobExtracts.CurrencyId = Currencies.Id
	INNER JOIN CurrencyCodes	
		ON Currencies.CurrencyCodeId = CurrencyCodes.Id
	INNER JOIN #InsertedRecords
		ON CollectionsJobExtracts.AllocatedQueueId = #InsertedRecords.CollectionQueueId AND
		   CollectionsJobExtracts.CustomerId = #InsertedRecords.CustomerId AND
		   CollectionsJobExtracts.CurrencyId = #InsertedRecords.CurrencyId AND
		   CollectionsJobExtracts.BusinessUnitId = #InsertedRecords.BusinessUnitId AND
		   (ISNULL(CollectionsJobExtracts.RemitToId, 0) = ISNULL(#InsertedRecords.RemitToId, 0))
	WHERE
		CollectionsJobExtracts.JobStepInstanceId = @JobStepInstanceId AND
		IsWorkListCreated = 0
	
END

GO
