SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[ReactivateBlendedItemAndSetEndDate]
(
@FutureInactiveBlendedItemIds NVARCHAR(MAX)
,@FutureActiveBlendedItemIds NVARCHAR(MAX)
--,@EndDate DATETIME = NULL
,@IsAccountingBlendedIncomeSchIds NVARCHAR(MAX)
,@IsScheduleBlendedIncomeSchIds NVARCHAR(MAX)
,@UserId BIGINT
,@CurrentTime DATETIMEOFFSET
,@ReversalPostDate DATETIME
,@RecognizeImmediatelyBookRecognitionMode NVARCHAR(MAX)
,@OneTimeOccurenceBI NVARCHAR(MAX)
,@AmortizeBookRecognitionMode NVARCHAR(MAX)
)
AS
BEGIN
SET NOCOUNT ON;
Select Id Into #FutureInactiveBlendedItemIds from ConvertCSVToBigIntTable(@FutureInactiveBlendedItemIds, ',');
Select Id Into #FutureActiveBlendedItemIds from ConvertCSVToBigIntTable(@FutureActiveBlendedItemIds, ',');

SELECT bi.Id 
INTO #SetUpGLPostedBlendedItemIds 
FROM BlendedItems bi
JOIN #FutureInactiveBlendedItemIds fibii On bi.Id = fibii.Id
WHERE (bi.BookRecognitionMode = @RecognizeImmediatelyBookRecognitionMode 
or (bi.Occurrence = @OneTimeOccurenceBI and BookRecognitionMode = @AmortizeBookRecognitionMode))

UPDATE BlendedItems SET IsActive = 1 , UpdatedById =  @UserId , UpdatedTime = @CurrentTime From BlendedItems bi
Join #FutureInactiveBlendedItemIds fibii On bi.Id = fibii.Id

UPDATE BlendedItemDetails 
SET 
IsActive = 1, 
IsGLPosted = CASE WHEN glbi.Id is NULL THEN bid.IsGLPosted ELSE 1 END,
PostDate = CASE WHEN glbi.Id is NULL THEN bid.PostDate ELSE @ReversalPostDate END,
UpdatedById =  @UserId , 
UpdatedTime = @CurrentTime 
From BlendedItemDetails bid
Join #FutureInactiveBlendedItemIds fibii On bid.BlendedItemId = fibii.Id
left join #SetUpGLPostedBlendedItemIds glbi on bid.BlendedItemId = glbi.Id

UPDATE BlendedIncomeSchedules SET IsAccounting = 0,IsSchedule = 0 ,UpdatedById = @UserId , UpdatedTime = @CurrentTime From BlendedIncomeSchedules bis
Join #FutureInactiveBlendedItemIds fibii On bis.Id = fibii.Id

UPDATE BlendedItems SET EndDate = CASE WHEN PBI.OriginalEndDate IS NOT NULL THEN PBI.OriginalEndDate Else EndDate END, IsActive = 1, UpdatedById = @UserId, UpdatedTime = @CurrentTime From BlendedItems bi
Join #FutureActiveBlendedItemIds fibii On bi.Id = fibii.Id
Join PayoffBlendedItems PBI on bi.Id  = PBI.BlendedItemId
END

GO
