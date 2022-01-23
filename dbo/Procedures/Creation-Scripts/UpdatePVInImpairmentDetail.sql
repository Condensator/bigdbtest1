SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[UpdatePVInImpairmentDetail]
(
@UpdateParam ImpairmentDetailPVUpdateTableType READONLY,
@ImpairmentId BIGINT,
@UserId BIGINT,
@Time DATETIMEOFFSET
)
AS
BEGIN
UPDATE LAD
SET LAD.PVOfAsset_Amount = UP.PVAmount,
LAD.PVOfAsset_Currency = UP.Currency,
LAD.UpdatedById = @UserId,
LAD.UpdatedTime = @Time
FROM LeaseAmendmentImpairmentAssetDetails LAD
JOIN LeaseAmendments LA ON LAD.LeaseAmendmentId = LA.Id
JOIN @UpdateParam UP ON LAD.AssetId = UP.AssetId
WHERE LAD.IsActive = 1
AND LA.Id = @ImpairmentId
;
END
;

GO
