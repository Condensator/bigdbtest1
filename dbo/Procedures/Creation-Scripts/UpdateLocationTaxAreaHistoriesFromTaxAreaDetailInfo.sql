SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[UpdateLocationTaxAreaHistoriesFromTaxAreaDetailInfo]
(
@LocationInfo LocationInfo READONLY,
@UpdatedTime DateTimeOffset,
@UpdatedById BIGINT,
@ApprovedLocationStatus NVARCHAR(32)
)
AS
BEGIN
UPDATE L SET L.TaxAreaId = LInfo.ChangedTaxAreaId,
L.UpdatedById = @UpdatedById,L.UpdatedTime = @UpdatedTime,
L.TaxAreaVerifiedTillDate = LInfo.AsOfDate
FROM Locations L
JOIN @LocationInfo LInfo ON L.Id = LInfo.LocationId
Where L.IsActive = 1 AND L.ApprovalStatus =  @ApprovedLocationStatus
INSERT INTO [dbo].[LocationTaxAreaHistories]
([TaxAreaId]
,[TaxAreaEffectiveDate]
,[CreatedById]
,[CreatedTime]
,[LocationId])
SELECT LInfo.ChangedTaxAreaId,
LInfo.AsOfDate,
@UpdatedById,
@UpdatedTime,
LInfo.LocationId
FROM @LocationInfo LInfo
WHERE LInfo.ChangedTaxAreaId IS NOT NULL
END

GO
