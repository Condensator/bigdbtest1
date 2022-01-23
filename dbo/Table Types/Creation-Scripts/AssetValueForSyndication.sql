CREATE TYPE [dbo].[AssetValueForSyndication] AS TABLE(
	[SourceModule] [nvarchar](25) COLLATE Latin1_General_CI_AS NOT NULL,
	[SourceModuleId] [bigint] NOT NULL,
	[IncomeDate] [date] NOT NULL,
	[PostDate] [date] NOT NULL,
	[Cost] [decimal](16, 2) NOT NULL,
	[BeginBookValue] [decimal](16, 2) NOT NULL,
	[EndBookValue] [decimal](16, 2) NOT NULL,
	[NetValue] [decimal](16, 2) NOT NULL,
	[Value] [decimal](16, 2) NOT NULL,
	[IsAccounted] [bit] NOT NULL,
	[IsSchedule] [bit] NOT NULL,
	[IsCleared] [bit] NOT NULL,
	[AssetId] [bigint] NOT NULL,
	[Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[GLJournalId] [bigint] NULL,
	[IsLeaseComponent] [bit] NULL
)
GO
