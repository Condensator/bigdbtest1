SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ActivityStatusForTypes](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Sequence] [int] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[IsDefault] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[StatusId] [bigint] NOT NULL,
	[WhomToNotifyId] [bigint] NOT NULL,
	[WhoCanChangeId] [bigint] NOT NULL,
	[ActivityTypeId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ActivityStatusForTypes]  WITH CHECK ADD  CONSTRAINT [EActivityStatusForType_Status] FOREIGN KEY([StatusId])
REFERENCES [dbo].[ActivityStatusConfigs] ([Id])
GO
ALTER TABLE [dbo].[ActivityStatusForTypes] CHECK CONSTRAINT [EActivityStatusForType_Status]
GO
ALTER TABLE [dbo].[ActivityStatusForTypes]  WITH CHECK ADD  CONSTRAINT [EActivityStatusForType_WhoCanChange] FOREIGN KEY([WhoCanChangeId])
REFERENCES [dbo].[UserSelectionParams] ([Id])
GO
ALTER TABLE [dbo].[ActivityStatusForTypes] CHECK CONSTRAINT [EActivityStatusForType_WhoCanChange]
GO
ALTER TABLE [dbo].[ActivityStatusForTypes]  WITH CHECK ADD  CONSTRAINT [EActivityStatusForType_WhomToNotify] FOREIGN KEY([WhomToNotifyId])
REFERENCES [dbo].[UserSelectionParams] ([Id])
GO
ALTER TABLE [dbo].[ActivityStatusForTypes] CHECK CONSTRAINT [EActivityStatusForType_WhomToNotify]
GO
ALTER TABLE [dbo].[ActivityStatusForTypes]  WITH CHECK ADD  CONSTRAINT [EActivityType_ActivityStatusForTypes] FOREIGN KEY([ActivityTypeId])
REFERENCES [dbo].[ActivityTypes] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[ActivityStatusForTypes] CHECK CONSTRAINT [EActivityType_ActivityStatusForTypes]
GO
