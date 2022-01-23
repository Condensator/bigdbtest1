SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[WorkItemActionConfigs](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[SequenceNumber] [int] NOT NULL,
	[ActionName] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsCommentRequired] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[WorkItemConfigId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[WorkItemActionConfigs]  WITH CHECK ADD  CONSTRAINT [EWorkItemConfig_WorkItemActionConfigs] FOREIGN KEY([WorkItemConfigId])
REFERENCES [dbo].[WorkItemConfigs] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[WorkItemActionConfigs] CHECK CONSTRAINT [EWorkItemConfig_WorkItemActionConfigs]
GO
