SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE   PROC [dbo].[UpdateSubscriptions](
@UpdatedTime DATETIMEOFFSET,
@UserId BIGINT,
@EntityName NVARCHAR(MAX),
@EntityId BIGINT,
@ActiveUserIds NVARCHAR(MAX)= '',
@InActiveUserIds NVARCHAR(MAX)= ''
)
AS
BEGIN

SELECT ti.Id
INTO #TransactionInstanceId
FROM dbo.TransactionInstances ti
WHERE ti.EntityId = @EntityId AND ti.EntityName = @EntityName AND ti.Status = 'Active';

Create Unique Clustered Index IX_Id On #TransactionInstanceId(Id)

SELECT * INTO #ActiveUserIds FROM dbo.ConvertCSVToBigIntTable(@ActiveUserIds, ',');

SELECT ti.Id TransactionInstanceId, aui.ID UserId
INTO #TransactionSubrictionForActivation
FROM #TransactionInstanceId ti
CROSS JOIN #ActiveUserIds aui
WHERE aui.ID != @UserId;

SELECT ts.Id TransactionSubscriberId, #TransactionInstanceId.Id TransactionInstanceId, #ActiveUserIds.ID UserId
INTO #ActiveExistingSubscribers
FROM dbo.TransactionSubscribers ts
INNER JOIN #TransactionInstanceId ON ts.TransactionInstanceId = #TransactionInstanceId.Id
INNER JOIN #ActiveUserIds ON ts.UserId = #ActiveUserIds.Id;

UPDATE dbo.TransactionSubscribers
SET dbo.TransactionSubscribers.Subscribed = 1, dbo.TransactionSubscribers.UpdatedById = @UserId, dbo.TransactionSubscribers.UpdatedTime = @UpdatedTime
WHERE ID IN(SELECT TransactionSubscriberId FROM #ActiveExistingSubscribers) And dbo.TransactionSubscribers.Subscribed = 0;

INSERT INTO dbo.TransactionSubscribers(Subscribed, CreatedById, CreatedTime, UserId, TransactionInstanceId)
SELECT DISTINCT  1, @UserId, @UpdatedTime, tsfa.UserId, tsfa.TransactionInstanceId
FROM #TransactionSubrictionForActivation tsfa
LEFT JOIN #ActiveExistingSubscribers aes ON tsfa.TransactionInstanceId = aes.TransactionInstanceId AND tsfa.UserId = aes.UserId
WHERE aes.TransactionSubscriberId IS NULL AND tsfa.UserId!=0;

IF @InActiveUserIds IS NOT NULL AND  @InActiveUserIds <> ''
	UPDATE dbo.TransactionSubscribers
	SET dbo.TransactionSubscribers.Subscribed = 0,
	dbo.TransactionSubscribers.UpdatedById = @UserId,
	dbo.TransactionSubscribers.UpdatedTime = @UpdatedTime
	FROM dbo.TransactionSubscribers ts
	JOIN #TransactionInstanceId ti ON ts.TransactionInstanceId = ti.Id
	JOIN dbo.ConvertCSVToBigIntTable(@InActiveUserIds, ',') iu ON ts.UserId = iu.Id

END;

GO
