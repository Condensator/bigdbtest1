SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[CreateAssetValueHistoryFromPayoff]
(
	@PayoffAssetValueHistoryInfo PayoffAssetValueHistoryInfo READONLY,
	@PayoffId BIGINT,
	@PayoffEffectiveDate DATETIME,
	@SourceModule NVARCHAR(40),
	@PostDate DATETIME,
	@GLJournalId BIGINT = NULL,
	@UserId BIGINT,
	@Currency NVARCHAR(3),
	@CreatedTime DATETIMEOFFSET
)
AS
BEGIN

SET NOCOUNT ON;
	
	INSERT INTO AssetValueHistories
		(SourceModule
		,SourceModuleId
		,IncomeDate
		,Value_Amount
		,Value_Currency
		,Cost_Amount
		,Cost_Currency
		,NetValue_Amount
		,NetValue_Currency
		,BeginBookValue_Amount
		,BeginBookValue_Currency
		,EndBookValue_Amount
		,EndBookValue_Currency
		,IsAccounted
		,IsSchedule
		,IsLessorOwned
		,IsCleared
		,PostDate
		,CreatedById
		,CreatedTime
		,AssetId
		,GLJournalId
		,AdjustmentEntry
		,IsLeaseComponent)
	SELECT
		@SourceModule
		,@PayoffId
		,@PayoffEffectiveDate
		,Value
		,@Currency
		,Cost
		,@Currency
		,NetValue
		,@Currency
		,BeginBookValue
		,@Currency
		,EndBookValue
		,@Currency
		,IsLessorOwned
		,1
		,IsLessorOwned
		,1
		,@PostDate
		,@UserId
		,@CreatedTime
		,AssetId
		,@GLJournalId
		,0
		,IsLeaseComponent
	FROM @PayoffAssetValueHistoryInfo AVHInfo

SET NOCOUNT OFF;

END

GO
