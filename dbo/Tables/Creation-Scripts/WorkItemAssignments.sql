SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[WorkItemAssignments](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[UserId] [bigint] NOT NULL,
	[WorkItemAssignmentConfigId] [bigint] NULL,
	[WorkItemId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[WorkItemAssignments]  WITH CHECK ADD  CONSTRAINT [EWorkItem_WorkItemAssignments] FOREIGN KEY([WorkItemId])
REFERENCES [dbo].[WorkItems] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[WorkItemAssignments] CHECK CONSTRAINT [EWorkItem_WorkItemAssignments]
GO
ALTER TABLE [dbo].[WorkItemAssignments]  WITH CHECK ADD  CONSTRAINT [EWorkItemAssignment_User] FOREIGN KEY([UserId])
REFERENCES [dbo].[Users] ([Id])
GO
ALTER TABLE [dbo].[WorkItemAssignments] CHECK CONSTRAINT [EWorkItemAssignment_User]
GO
ALTER TABLE [dbo].[WorkItemAssignments]  WITH CHECK ADD  CONSTRAINT [EWorkItemAssignment_WorkItemAssignmentConfig] FOREIGN KEY([WorkItemAssignmentConfigId])
REFERENCES [dbo].[WorkItemAssignmentConfigs] ([Id])
GO
ALTER TABLE [dbo].[WorkItemAssignments] CHECK CONSTRAINT [EWorkItemAssignment_WorkItemAssignmentConfig]
GO
