SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DocumentStatusSubSystemConfigs](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Status] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[SubSystemId] [bigint] NOT NULL,
	[DocumentStatusConfigId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[DocumentStatusSubSystemConfigs]  WITH CHECK ADD  CONSTRAINT [EDocumentStatusConfig_DocumentStatusSubSystemConfigs] FOREIGN KEY([DocumentStatusConfigId])
REFERENCES [dbo].[DocumentStatusConfigs] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[DocumentStatusSubSystemConfigs] CHECK CONSTRAINT [EDocumentStatusConfig_DocumentStatusSubSystemConfigs]
GO
ALTER TABLE [dbo].[DocumentStatusSubSystemConfigs]  WITH CHECK ADD  CONSTRAINT [EDocumentStatusSubSystemConfig_SubSystem] FOREIGN KEY([SubSystemId])
REFERENCES [dbo].[SubSystemConfigs] ([Id])
GO
ALTER TABLE [dbo].[DocumentStatusSubSystemConfigs] CHECK CONSTRAINT [EDocumentStatusSubSystemConfig_SubSystem]
GO
