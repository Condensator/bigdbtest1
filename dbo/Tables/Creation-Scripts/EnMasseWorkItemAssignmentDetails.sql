SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[EnMasseWorkItemAssignmentDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[WorkItemId] [bigint] NOT NULL,
	[EnMasseWorkItemAssignmentId] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[EnMasseWorkItemAssignmentDetails]  WITH CHECK ADD  CONSTRAINT [EEnMasseWorkItemAssignment_EnMasseWorkItemAssignmentDetails] FOREIGN KEY([EnMasseWorkItemAssignmentId])
REFERENCES [dbo].[EnMasseWorkItemAssignments] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[EnMasseWorkItemAssignmentDetails] CHECK CONSTRAINT [EEnMasseWorkItemAssignment_EnMasseWorkItemAssignmentDetails]
GO
ALTER TABLE [dbo].[EnMasseWorkItemAssignmentDetails]  WITH CHECK ADD  CONSTRAINT [EEnMasseWorkItemAssignmentDetail_WorkItem] FOREIGN KEY([WorkItemId])
REFERENCES [dbo].[WorkItems] ([Id])
GO
ALTER TABLE [dbo].[EnMasseWorkItemAssignmentDetails] CHECK CONSTRAINT [EEnMasseWorkItemAssignmentDetail_WorkItem]
GO
