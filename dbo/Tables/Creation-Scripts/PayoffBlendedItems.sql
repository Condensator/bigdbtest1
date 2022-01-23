SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PayoffBlendedItems](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Earned_Amount] [decimal](16, 2) NOT NULL,
	[Earned_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Unearned_Amount] [decimal](16, 2) NOT NULL,
	[Unearned_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[PayoffAdjustment_Amount] [decimal](16, 2) NOT NULL,
	[PayoffAdjustment_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[AccumulatedAdjustment_Amount] [decimal](16, 2) NOT NULL,
	[AccumulatedAdjustment_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[BilledAmount_Amount] [decimal](16, 2) NOT NULL,
	[BilledAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[UnbilledAmount_Amount] [decimal](16, 2) NOT NULL,
	[UnbilledAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[InactivatedInLease] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[BlendedItemId] [bigint] NOT NULL,
	[GLJournalId] [bigint] NULL,
	[PayoffId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[OriginalEndDate] [date] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[PayoffBlendedItems]  WITH CHECK ADD  CONSTRAINT [EPayoff_PayoffBlendedItems] FOREIGN KEY([PayoffId])
REFERENCES [dbo].[Payoffs] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[PayoffBlendedItems] CHECK CONSTRAINT [EPayoff_PayoffBlendedItems]
GO
ALTER TABLE [dbo].[PayoffBlendedItems]  WITH CHECK ADD  CONSTRAINT [EPayoffBlendedItem_BlendedItem] FOREIGN KEY([BlendedItemId])
REFERENCES [dbo].[BlendedItems] ([Id])
GO
ALTER TABLE [dbo].[PayoffBlendedItems] CHECK CONSTRAINT [EPayoffBlendedItem_BlendedItem]
GO
ALTER TABLE [dbo].[PayoffBlendedItems]  WITH CHECK ADD  CONSTRAINT [EPayoffBlendedItem_GLJournal] FOREIGN KEY([GLJournalId])
REFERENCES [dbo].[GLJournals] ([Id])
GO
ALTER TABLE [dbo].[PayoffBlendedItems] CHECK CONSTRAINT [EPayoffBlendedItem_GLJournal]
GO
