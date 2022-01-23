SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[JobsForParties](
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[PartyId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[JobsForParties]  WITH CHECK ADD  CONSTRAINT [EJob_JobsForParty] FOREIGN KEY([Id])
REFERENCES [dbo].[Jobs] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[JobsForParties] CHECK CONSTRAINT [EJob_JobsForParty]
GO
ALTER TABLE [dbo].[JobsForParties]  WITH CHECK ADD  CONSTRAINT [EJobsForParty_Party] FOREIGN KEY([PartyId])
REFERENCES [dbo].[Parties] ([Id])
GO
ALTER TABLE [dbo].[JobsForParties] CHECK CONSTRAINT [EJobsForParty_Party]
GO
