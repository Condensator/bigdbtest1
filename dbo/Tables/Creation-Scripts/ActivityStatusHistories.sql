SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ActivityStatusHistories](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[AsOfDate] [date] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ChangedById] [bigint] NOT NULL,
	[StatusId] [bigint] NOT NULL,
	[ActivityId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ActivityStatusHistories]  WITH CHECK ADD  CONSTRAINT [EActivity_ActivityStatusHistories] FOREIGN KEY([ActivityId])
REFERENCES [dbo].[Activities] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[ActivityStatusHistories] CHECK CONSTRAINT [EActivity_ActivityStatusHistories]
GO
ALTER TABLE [dbo].[ActivityStatusHistories]  WITH CHECK ADD  CONSTRAINT [EActivityStatusHistory_ChangedBy] FOREIGN KEY([ChangedById])
REFERENCES [dbo].[Users] ([Id])
GO
ALTER TABLE [dbo].[ActivityStatusHistories] CHECK CONSTRAINT [EActivityStatusHistory_ChangedBy]
GO
ALTER TABLE [dbo].[ActivityStatusHistories]  WITH CHECK ADD  CONSTRAINT [EActivityStatusHistory_Status] FOREIGN KEY([StatusId])
REFERENCES [dbo].[ActivityStatusConfigs] ([Id])
GO
ALTER TABLE [dbo].[ActivityStatusHistories] CHECK CONSTRAINT [EActivityStatusHistory_Status]
GO
