SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[UpdateLeaseBlendedIncomeSchedulesAndInactivateParentItems]
(
@BlendedItemMapping LeaseBlendedItemMappingType READONLY,
@RestructureDate DATETIME,
@UpdatedById BIGINT,
@UpdatedTime DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON;
UPDATE BIS
SET BIS.BlendedItemId = BIU.BlendedItemId,
BIS.UpdatedById = @UpdatedById,
BIS.UpdatedTime = @UpdatedTime
FROM BlendedIncomeSchedules BIS
JOIN @BlendedItemMapping BIU ON BIS.BlendedItemId = BIU.ParentBlendedItemId
WHERE BIS.IsSchedule = 1
OR BIS.IsAccounting = 1
;
UPDATE BlendedItems
SET IsActive = 0,
UpdatedById = @UpdatedById,
UpdatedTime = @UpdatedTime
WHERE Id IN (SELECT ParentBlendedItemId FROM @BlendedItemMapping)
;
SET NOCOUNT OFF;
END

GO
