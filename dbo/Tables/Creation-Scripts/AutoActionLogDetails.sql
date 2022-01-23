SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AutoActionLogDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[EntityId] [bigint] NOT NULL,
	[IsSuccess] [bit] NOT NULL,
	[WorkItemId] [bigint] NULL,
	[CommentId] [bigint] NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[AutoActionLogId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[AutoActionLogDetails]  WITH CHECK ADD  CONSTRAINT [EAutoActionLog_AutoActionLogDetails] FOREIGN KEY([AutoActionLogId])
REFERENCES [dbo].[AutoActionLogs] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[AutoActionLogDetails] CHECK CONSTRAINT [EAutoActionLog_AutoActionLogDetails]
GO
