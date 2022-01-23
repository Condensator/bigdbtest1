SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[InactivateResidualReclassRecordsFromPayoff]
(
@AssetsToUpdate Payoff_AssetsToInactivateResidualReclassRecords READONLY,
@ResidualReclassType NVARCHAR(30),
@ReversalGLJournalId BIGINT = NULL,
@PayoffEffectiveDate DATE,
@UserId BIGINT,
@UpdatedTime DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON
UPDATE AVH SET
AVH.IsSchedule = 0,
AVH.IsAccounted = 0,
AVH.ReversalGLJournalId = @ReversalGLJournalId,
AVH.UpdatedTime = @UpdatedTime,
AVH.UpdatedById = @UserId
FROM AssetValueHistories AVH
JOIN @AssetsToUpdate A ON AVH.AssetId = A.Id
WHERE AVH.SourceModule = @ResidualReclassType
AND ((AVH.IsAccounted = 1 OR AVH.IsSchedule = 1) AND AVH.IsLessorOwned = 1)
AND AVH.IncomeDate > @PayoffEffectiveDate;
END

GO
