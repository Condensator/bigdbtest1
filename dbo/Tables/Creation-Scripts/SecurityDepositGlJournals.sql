SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SecurityDepositGlJournals](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[PostDate] [date] NOT NULL,
	[IsReversal] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[GlJournalId] [bigint] NOT NULL,
	[SecurityDepositAllocationId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[SecurityDepositGlJournals]  WITH CHECK ADD  CONSTRAINT [ESecurityDepositAllocation_SecurityDepositGlJournals] FOREIGN KEY([SecurityDepositAllocationId])
REFERENCES [dbo].[SecurityDepositAllocations] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[SecurityDepositGlJournals] CHECK CONSTRAINT [ESecurityDepositAllocation_SecurityDepositGlJournals]
GO
ALTER TABLE [dbo].[SecurityDepositGlJournals]  WITH CHECK ADD  CONSTRAINT [ESecurityDepositGlJournal_GlJournal] FOREIGN KEY([GlJournalId])
REFERENCES [dbo].[GLJournals] ([Id])
GO
ALTER TABLE [dbo].[SecurityDepositGlJournals] CHECK CONSTRAINT [ESecurityDepositGlJournal_GlJournal]
GO
