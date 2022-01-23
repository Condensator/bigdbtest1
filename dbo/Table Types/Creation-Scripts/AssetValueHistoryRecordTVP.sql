CREATE TYPE [dbo].[AssetValueHistoryRecordTVP] AS TABLE(
	[SourceModule] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[SourceModuleId] [bigint] NULL,
	[FromDate] [datetime] NULL,
	[ToDate] [datetime] NULL,
	[IncomeDate] [datetime] NULL,
	[ValueAmount] [decimal](18, 2) NULL,
	[Cost] [decimal](18, 2) NULL,
	[NetValue] [decimal](18, 2) NULL,
	[BeginBookValue] [decimal](18, 2) NULL,
	[EndBookValue] [decimal](18, 2) NULL,
	[IsAccounted] [bit] NULL,
	[IsSchedule] [bit] NULL,
	[IsCleared] [bit] NULL,
	[IsLessorOwned] [bit] NULL,
	[PostDate] [datetime] NULL,
	[AssetId] [bigint] NULL,
	[Currency] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[IsLeaseComponent] [bit] NULL
)
GO
