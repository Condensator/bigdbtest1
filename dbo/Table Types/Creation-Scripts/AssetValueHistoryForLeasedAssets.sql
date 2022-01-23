CREATE TYPE [dbo].[AssetValueHistoryForLeasedAssets] AS TABLE(
	[SourceModule] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[SourceModuleId] [bigint] NULL,
	[FromDate] [datetime] NULL,
	[ToDate] [datetime] NULL,
	[IncomeDate] [datetime] NULL,
	[ValueAmount] [decimal](18, 2) NULL,
	[NetValueAmount] [decimal](18, 2) NULL,
	[CostAmount] [decimal](18, 2) NULL,
	[BeginBookValueAmount] [decimal](18, 2) NULL,
	[EndBookValueAmount] [decimal](18, 2) NULL,
	[IsAccounted] [bit] NULL,
	[IsSchedule] [bit] NULL,
	[IsCleared] [bit] NULL,
	[PostDate] [datetime] NULL,
	[AssetId] [bigint] NOT NULL,
	[MatchingAssetId] [bigint] NULL,
	[GLJournalId] [bigint] NULL,
	[AdjustmentEntry] [bit] NULL,
	[Currency] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[IsLessorOwned] [bit] NULL,
	[IsLeaseComponent] [bit] NULL,
	INDEX [IX_AssetId] NONCLUSTERED 
(
	[AssetId] ASC
)
)
GO
