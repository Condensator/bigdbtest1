SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[UpdateAVHResidualReclassRecordsFromPaidOffAssets]
(
@AssetsToUpdate Payoff_AssetsToInactivateResidualReclassRecordsForOTPDep READONLY,
@PayoffEffectiveDate DATE,
@UserId BIGINT,
@UpdatedTime DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON
UPDATE AVH 
SET
AVH.IsSchedule = 0,
AVH.IsAccounted = 0,
AVH.ReversalGLJournalId = A.ReversalGLJournalId,
AVH.ReversalPostDate = A.ReversalPostDate,
AVH.UpdatedTime = @UpdatedTime,
AVH.UpdatedById = @UserId
FROM AssetValueHistories AVH
JOIN @AssetsToUpdate A ON AVH.AssetId = A.AssetId
AND (AVH.IsLeaseComponent = A.IsLeaseComponent OR (A.IsFailedSaleLeaseBack = 1 AND  AVH.IsLeaseComponent != A.IsLeaseComponent))
WHERE AVH.SourceModule = 'ResidualReclass'
AND ((AVH.IsAccounted = 1 OR AVH.IsSchedule = 1) AND AVH.IsLessorOwned = 1)
AND AVH.IncomeDate > @PayoffEffectiveDate;
END

GO
