SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AssetValueHistories](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[SourceModule] [nvarchar](25) COLLATE Latin1_General_CI_AS NOT NULL,
	[SourceModuleId] [bigint] NOT NULL,
	[FromDate] [date] NULL,
	[ToDate] [date] NULL,
	[IncomeDate] [date] NOT NULL,
	[Value_Amount] [decimal](16, 2) NOT NULL,
	[Value_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Cost_Amount] [decimal](16, 2) NOT NULL,
	[Cost_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[NetValue_Amount] [decimal](16, 2) NOT NULL,
	[NetValue_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[BeginBookValue_Amount] [decimal](16, 2) NOT NULL,
	[BeginBookValue_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[EndBookValue_Amount] [decimal](16, 2) NOT NULL,
	[EndBookValue_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsAccounted] [bit] NOT NULL,
	[IsSchedule] [bit] NOT NULL,
	[IsCleared] [bit] NOT NULL,
	[PostDate] [date] NULL,
	[ReversalPostDate] [date] NULL,
	[AdjustmentEntry] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[AssetId] [bigint] NOT NULL,
	[GLJournalId] [bigint] NULL,
	[ReversalGLJournalId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[IsLessorOwned] [bit] NOT NULL,
	[IsLeaseComponent] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[AssetValueHistories]  WITH CHECK ADD  CONSTRAINT [EAssetValueHistory_Asset] FOREIGN KEY([AssetId])
REFERENCES [dbo].[Assets] ([Id])
GO
ALTER TABLE [dbo].[AssetValueHistories] CHECK CONSTRAINT [EAssetValueHistory_Asset]
GO
ALTER TABLE [dbo].[AssetValueHistories]  WITH CHECK ADD  CONSTRAINT [EAssetValueHistory_GLJournal] FOREIGN KEY([GLJournalId])
REFERENCES [dbo].[GLJournals] ([Id])
GO
ALTER TABLE [dbo].[AssetValueHistories] CHECK CONSTRAINT [EAssetValueHistory_GLJournal]
GO
ALTER TABLE [dbo].[AssetValueHistories]  WITH CHECK ADD  CONSTRAINT [EAssetValueHistory_ReversalGLJournal] FOREIGN KEY([ReversalGLJournalId])
REFERENCES [dbo].[GLJournals] ([Id])
GO
ALTER TABLE [dbo].[AssetValueHistories] CHECK CONSTRAINT [EAssetValueHistory_ReversalGLJournal]
GO
