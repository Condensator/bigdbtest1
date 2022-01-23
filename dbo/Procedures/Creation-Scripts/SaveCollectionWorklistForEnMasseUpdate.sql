SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

Create Proc [dbo].[SaveCollectionWorklistForEnMasseUpdate]
(
@enMasseUpdateDetails EnMasseCollectionWorklistUpdateTempTable READONLY
,@CollectionWorkListStatusOpen NVarChar(11)
,@CollectionWorkListStatusHibernation NVarChar(11)
,@UpdatedById Bigint
,@UpdatedTime Datetimeoffset
)
As
Begin

SELECT Distinct CustomerId,CollectionQueueId,MU.PrimaryCollectorId INTO #CustomerQueueCombinations
FROM CollectionWorkLists
JOIN  @enMasseUpdateDetails MU on CollectionWorkLists.Id = MU.CollectionWorklistId

SELECT CollectionWorkLists.Id,CollectionWorkLists.CustomerId,CollectionWorkLists.CollectionQueueId,CollectionWorkLists.NextWorkDate,CollectionWorkLists.Status,#CustomerQueueCombinations.PrimaryCollectorId
INTO #RelatedCollectionWorkLists
FROM CollectionWorkLists
JOIN #CustomerQueueCombinations on CollectionWorkLists.CustomerId = #CustomerQueueCombinations.CustomerId AND CollectionWorkLists.CollectionQueueId = #CustomerQueueCombinations.CollectionQueueId
LEFT JOIN @enMasseUpdateDetails ParentCollectionWorkLists on CollectionWorkLists.Id = ParentCollectionWorkLists.CollectionWorklistId
WHERE ParentCollectionWorkLists.CollectionWorklistId IS NULL  
AND CollectionWorkLists.Status IN (@CollectionWorkListStatusOpen,@CollectionWorkListStatusHibernation)

Update CollectionWorkLists Set Status = MU.Status
,NextWorkDate = MU.NextWorkDate
,PrimaryCollectorId = MU.PrimaryCollectorId
,UpdatedById = @UpdatedById
,UpdatedTime = @UpdatedTime
From @enMasseUpdateDetails MU
Join CollectionWorkLists On
MU.CollectionWorklistId = CollectionWorkLists.Id

Update CollectionWorkLists SET
PrimaryCollectorId = #RelatedCollectionWorkLists.PrimaryCollectorId
,UpdatedById = @UpdatedById
,UpdatedTime = @UpdatedTime
FROM #RelatedCollectionWorkLists
JOIN CollectionWorkLists ON #RelatedCollectionWorkLists.Id = CollectionWorkLists.Id

UPDATE CollectionWorkListContractDetails SET IsWorkCompleted = 1,CompletionReason = MU.ClosureReason
FROM CollectionWorkListContractDetails
JOIN @enMasseUpdateDetails MU ON CollectionWorkListContractDetails.CollectionWorkListId = MU.CollectionWorklistId
JOIN CollectionWorkLists ON MU.CollectionWorklistId = CollectionWorkLists.Id
WHERE MU.ClosureReason IS NOT NULL

End

GO
