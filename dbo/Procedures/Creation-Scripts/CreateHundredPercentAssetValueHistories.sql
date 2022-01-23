SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[CreateHundredPercentAssetValueHistories]
(
	@BooKDepreciationRecords BooKDepreciationRecordTVP READONLY,
	@AssetValueHistoryRecords AssetValueHistoryRecordTVP READONLY,
	@CreatedById BIGINT,
	@CreatedTime DATETIMEOFFSET(7)
)
AS

SET NOCOUNT ON;

INSERT INTO BookDepreciations
(
	AssetId,
	CostBasis_Amount,
	CostBasis_Currency,
	Salvage_Amount,
	Salvage_Currency,
	BeginDate,
	EndDate,
	TerminatedDate,
	GLTemplateId,
	InstrumentTypeId,
	LineofBusinessId,
	CostCenterId,
	ContractId,
	IsActive,
	RemainingLifeInMonths,
	IsInOTP,
	PerDayDepreciationFactor,
	IsLessorOwned,
	LastAmortRunDate,
	CreatedById,
	CreatedTime,
	IsLeaseComponent 
)
SELECT
	BookDep.AssetId,
	BookDep.CostBasis,
	BookDep.Currency,
	BookDep.Salvage,
	BookDep.Currency,
	BookDep.BeginDate,
	BookDep.EndDate,
	BookDep.TerminatedDate,
	BookDep.GLTemplateId,
	BookDep.InstrumentTypeId,
	BookDep.LineofBusinessId,
	BookDep.CostCenterId,
	BookDep.ContractId,
	BookDep.IsActive,
	0,
	0,
	BookDep.PerDayDepreciationFactor,
	BookDep.IsLessorOwned,
	BookDep.EndDate,
	@CreatedById,
	@CreatedTime,
	IsLeaseComponent
FROM @BooKDepreciationRecords BookDep

INSERT INTO AssetValueHistories
(
	 SourceModule
    ,SourceModuleId
    ,FromDate
    ,ToDate
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
    ,IsCleared
    ,PostDate
	,AssetId
    ,IsLessorOwned
	,AdjustmentEntry
    ,CreatedById
    ,CreatedTime
	,IsLeaseComponent
)
SELECT
	AVH.SourceModule,
	AVH.SourceModuleId,
	AVH.FromDate,
	AVH.ToDate,
	AVH.IncomeDate,
	AVH.ValueAmount,
	AVH.Currency,
	AVH.Cost,
	AVH.Currency,
	AVH.NetValue,
	AVH.Currency,
	AVH.BeginBookValue,
	AVH.Currency,
	AVH.EndBookValue,
	AVH.Currency,
	AVH.IsAccounted,
	AVH.IsSchedule,
	AVH.IsCleared,
	AVH.PostDate,
	AVH.AssetId,
	AVH.IsLessorOwned,
	0,
	@CreatedById,
	@CreatedTime,
	IsLeaseComponent
FROM @AssetValueHistoryRecords AVH



GO
