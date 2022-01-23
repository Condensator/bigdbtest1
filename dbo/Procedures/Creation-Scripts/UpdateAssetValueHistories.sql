SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[UpdateAssetValueHistories]
(
	@UpdatedAssetValueHistoryInputs UpdatedAssetValueHistories READONLY,
	@UserId	BIGINT,
	@UpdatedTime DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON;

	UPDATE AssetValueHistories
	SET
		IsSchedule = UAVH.IsSchedule,
		IsAccounted = UAVH.IsAccounted,
		ReversalPostDate = UAVH.ReversalPostDate,
		ReversalGLJournalId = UAVH.ReversalGlJournalId,
		UpdatedTime = @UpdatedTime,
		UpdatedById = @UserId
	FROM AssetValueHistories
	JOIN @UpdatedAssetValueHistoryInputs UAVH ON UAVH.AssetValueHistoryId = AssetValueHistories.Id

END

GO
