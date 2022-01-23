SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DocumentStatusHistories](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[AsOfDate] [date] NOT NULL,
	[Comment] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[RowNumber] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[StatusId] [bigint] NOT NULL,
	[StatusChangedById] [bigint] NOT NULL,
	[DocumentInstanceId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[DocumentStatusHistories]  WITH CHECK ADD  CONSTRAINT [EDocumentInstance_DocumentStatusHistories] FOREIGN KEY([DocumentInstanceId])
REFERENCES [dbo].[DocumentInstances] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[DocumentStatusHistories] CHECK CONSTRAINT [EDocumentInstance_DocumentStatusHistories]
GO
ALTER TABLE [dbo].[DocumentStatusHistories]  WITH CHECK ADD  CONSTRAINT [EDocumentStatusHistory_Status] FOREIGN KEY([StatusId])
REFERENCES [dbo].[DocumentStatusConfigs] ([Id])
GO
ALTER TABLE [dbo].[DocumentStatusHistories] CHECK CONSTRAINT [EDocumentStatusHistory_Status]
GO
ALTER TABLE [dbo].[DocumentStatusHistories]  WITH CHECK ADD  CONSTRAINT [EDocumentStatusHistory_StatusChangedBy] FOREIGN KEY([StatusChangedById])
REFERENCES [dbo].[Users] ([Id])
GO
ALTER TABLE [dbo].[DocumentStatusHistories] CHECK CONSTRAINT [EDocumentStatusHistory_StatusChangedBy]
GO
