SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[UpdateGLPostedFlag]
(
@GLPostTable GLPostTable READONLY,
@UserId BIGINT,
@UpdateTime DATETIMEOFFSET
)
AS
SET NOCOUNT ON
Update LoanCapitalizedInterests
SET LoanCapitalizedInterests.GLJournalId = TVP.GLJournalId,UpdatedById=@UserId,UpdatedTime=@UpdateTime
FROM LoanCapitalizedInterests
INNER JOIN @GLPostTable TVP ON LoanCapitalizedInterests.Id = TVP.PrimaryId
WHERE TVP.TableName = 'LoanCapitalizedInterests'
Update LoanIncomeSchedules
SET LoanIncomeSchedules.IsGLPosted = TVP.IsGLPosted,UpdatedById=@UserId,UpdatedTime=@UpdateTime
FROM LoanIncomeSchedules
INNER JOIN @GLPostTable TVP ON LoanIncomeSchedules.Id = TVP.PrimaryId
WHERE TVP.TableName = 'LoanIncomeSchedules'
Update LeaseIncomeSchedules
SET LeaseIncomeSchedules.IsGLPosted = TVP.IsGLPosted, LeaseIncomeSchedules.PostDate = TVP.PostDate,UpdatedById=@UserId,UpdatedTime=@UpdateTime
FROM LeaseIncomeSchedules
INNER JOIN @GLPostTable TVP ON LeaseIncomeSchedules.Id = TVP.PrimaryId
WHERE TVP.TableName = 'LeaseIncomeSchedules'
Update LeaseFloatRateIncomes
SET LeaseFloatRateIncomes.IsGLPosted = TVP.IsGLPosted,UpdatedById=@UserId,UpdatedTime=@UpdateTime
FROM LeaseFloatRateIncomes
INNER JOIN @GLPostTable TVP ON LeaseFloatRateIncomes.Id = TVP.PrimaryId
WHERE TVP.TableName = 'LeaseFloatRateIncomes'
Update AssetValueHistories
SET AssetValueHistories.PostDate = TVP.PostDate, AssetValueHistories.GLJournalId = TVP.GLJournalId,UpdatedById=@UserId,UpdatedTime=@UpdateTime
FROM AssetValueHistories
INNER JOIN @GLPostTable TVP ON AssetValueHistories.Id = TVP.PrimaryId
WHERE TVP.TableName = 'AssetValueHistories'
Update BlendedItemDetails
SET BlendedItemDetails.PostDate = TVP.PostDate, BlendedItemDetails.IsGLPosted = TVP.IsGLPosted,UpdatedById=@UserId,UpdatedTime=@UpdateTime
FROM BlendedItemDetails
INNER JOIN @GLPostTable TVP ON BlendedItemDetails.Id = TVP.PrimaryId
WHERE TVP.TableName = 'BlendedItemDetails'
Update BlendedIncomeSchedules
SET BlendedIncomeSchedules.PostDate = TVP.PostDate,UpdatedById=@UserId,UpdatedTime=@UpdateTime
FROM BlendedIncomeSchedules
INNER JOIN @GLPostTable TVP ON BlendedIncomeSchedules.Id = TVP.PrimaryId
WHERE TVP.TableName = 'BlendedIncomeSchedules'
Update LeveragedLeaseAmorts
SET LeveragedLeaseAmorts.IsGLPosted = TVP.IsGLPosted,UpdatedById=@UserId,UpdatedTime=@UpdateTime
FROM LeveragedLeaseAmorts
INNER JOIN @GLPostTable TVP ON LeveragedLeaseAmorts.Id = TVP.PrimaryId
WHERE TVP.TableName = 'LeveragedLeaseAmorts'

GO
