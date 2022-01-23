SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[UpdateLoanBlendedIncomeSchedules]
(
@BlendedItemIds NVARCHAR(MAX),
@RestructureDate DATETIME,
@UpdatedById BIGINT,
@UpdatedTime DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON;
SELECT BI.Id AS BlendedItemId ,BI.ParentBlendedItemId AS ParentBlendedItemId INTO #BlendedItemIdsToUpdate FROM BlendedItems BI
INNER JOIN ConvertCSVToBigIntTable(@BlendedItemIds,',') q on BI.Id = q.ID
Update BlendedIncomeSchedules
Set BlendedItemId = BIU.BlendedItemId
,UpdatedById = @UpdatedById
,UpdatedTime = @UpdatedTime
FROM BlendedIncomeSchedules BIS
JOIN #BlendedItemIdsToUpdate BIU ON BIS.BlendedItemId = BIU.ParentBlendedItemId
WHERE IncomeDate < @RestructureDate
END

GO
