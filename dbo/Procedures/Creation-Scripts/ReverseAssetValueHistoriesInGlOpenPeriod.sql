SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[ReverseAssetValueHistoriesInGlOpenPeriod]
(
@AssetValueHistoryDetails AssetValueHistoriesInGLOpenPeriodParam READONLY,
@UpdatedTime DATETIMEOFFSET,
@UserId BIGINT
)
AS
BEGIN
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
UPDATE AVH
SET AVH.IsSchedule = PARAM.IsSchedule
,AVH.IsAccounted = PARAM.IsAccounted
,AVH.ReversalGLJournalId = PARAM.ReversalGLJournalId
,AVH.ReversalPostDate = PARAM.ReversalPostDate
,AVH.UpdatedById = @UserId
,AVH.UpdatedTime = @UpdatedTime
FROM AssetValueHistories AVH
JOIN @AssetValueHistoryDetails PARAM ON AVH.Id = PARAM.AVHId
;
SET NOCOUNT OFF;
END

GO
