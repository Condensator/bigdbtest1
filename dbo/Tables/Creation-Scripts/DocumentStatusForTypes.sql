SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DocumentStatusForTypes](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Sequence] [int] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[StatusId] [bigint] NOT NULL,
	[DocumentTypeId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[IsDefault] [bit] NOT NULL,
	[WhoCanChangeId] [bigint] NOT NULL,
	[WhomToNotifyId] [bigint] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[DocumentStatusForTypes]  WITH CHECK ADD  CONSTRAINT [EDocumentStatusForType_Status] FOREIGN KEY([StatusId])
REFERENCES [dbo].[DocumentStatusConfigs] ([Id])
GO
ALTER TABLE [dbo].[DocumentStatusForTypes] CHECK CONSTRAINT [EDocumentStatusForType_Status]
GO
ALTER TABLE [dbo].[DocumentStatusForTypes]  WITH CHECK ADD  CONSTRAINT [EDocumentStatusForType_WhoCanChange] FOREIGN KEY([WhoCanChangeId])
REFERENCES [dbo].[UserSelectionParams] ([Id])
GO
ALTER TABLE [dbo].[DocumentStatusForTypes] CHECK CONSTRAINT [EDocumentStatusForType_WhoCanChange]
GO
ALTER TABLE [dbo].[DocumentStatusForTypes]  WITH CHECK ADD  CONSTRAINT [EDocumentStatusForType_WhomToNotify] FOREIGN KEY([WhomToNotifyId])
REFERENCES [dbo].[UserSelectionParams] ([Id])
GO
ALTER TABLE [dbo].[DocumentStatusForTypes] CHECK CONSTRAINT [EDocumentStatusForType_WhomToNotify]
GO
ALTER TABLE [dbo].[DocumentStatusForTypes]  WITH CHECK ADD  CONSTRAINT [EDocumentType_DocumentStatusForTypes] FOREIGN KEY([DocumentTypeId])
REFERENCES [dbo].[DocumentTypes] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[DocumentStatusForTypes] CHECK CONSTRAINT [EDocumentType_DocumentStatusForTypes]
GO
