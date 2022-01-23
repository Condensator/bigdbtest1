SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[UpdateOpenPeriodBlendedIncomesForNonAccrual]
(
@BlendedIncomeIds BlendedIncomeIdInfoForNA READONLY,
@UserId BIGINT,
@ModificationTime DATETIMEOFFSET
)
AS
BEGIN
UPDATE BIS SET
BIS.IsNonAccrual = 1,
BIS.ReversalPostDate = BLI.ReversalPostDate,
BIS.PostDate = CASE WHEN BLI.ReversalPostDate IS NOT NULL THEN NULL ELSE BIS.PostDate END,
UpdatedById = @UserId,
UpdatedTime = @ModificationTime
FROM BlendedIncomeSchedules BIS
JOIN @BlendedIncomeIds BLI ON  BIS.Id = BLI.Id
END

GO
