SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ActivityLists](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsManual] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ActivityId] [bigint] NOT NULL,
	[ActivityHeaderId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ActivityLists]  WITH CHECK ADD  CONSTRAINT [EActivityHeader_ActivityLists] FOREIGN KEY([ActivityHeaderId])
REFERENCES [dbo].[ActivityHeaders] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[ActivityLists] CHECK CONSTRAINT [EActivityHeader_ActivityLists]
GO
ALTER TABLE [dbo].[ActivityLists]  WITH CHECK ADD  CONSTRAINT [EActivityList_Activity] FOREIGN KEY([ActivityId])
REFERENCES [dbo].[Activities] ([Id])
GO
ALTER TABLE [dbo].[ActivityLists] CHECK CONSTRAINT [EActivityList_Activity]
GO
