SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DocumentTypeSubSystemDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Viewable] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[SubSystemId] [bigint] NOT NULL,
	[DocumentTypeId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[DocumentTypeSubSystemDetails]  WITH CHECK ADD  CONSTRAINT [EDocumentType_DocumentTypeSubSystemDetails] FOREIGN KEY([DocumentTypeId])
REFERENCES [dbo].[DocumentTypes] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[DocumentTypeSubSystemDetails] CHECK CONSTRAINT [EDocumentType_DocumentTypeSubSystemDetails]
GO
ALTER TABLE [dbo].[DocumentTypeSubSystemDetails]  WITH CHECK ADD  CONSTRAINT [EDocumentTypeSubSystemDetail_SubSystem] FOREIGN KEY([SubSystemId])
REFERENCES [dbo].[SubSystemConfigs] ([Id])
GO
ALTER TABLE [dbo].[DocumentTypeSubSystemDetails] CHECK CONSTRAINT [EDocumentTypeSubSystemDetail_SubSystem]
GO
