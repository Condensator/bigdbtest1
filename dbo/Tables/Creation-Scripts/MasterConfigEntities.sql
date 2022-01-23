SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[MasterConfigEntities](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[EntityName] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[ExcelSheetName] [nvarchar](30) COLLATE Latin1_General_CI_AS NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ParentEntityId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[TableName] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[MasterConfigEntities]  WITH CHECK ADD  CONSTRAINT [EMasterConfigEntity_ParentEntity] FOREIGN KEY([ParentEntityId])
REFERENCES [dbo].[MasterConfigEntities] ([Id])
GO
ALTER TABLE [dbo].[MasterConfigEntities] CHECK CONSTRAINT [EMasterConfigEntity_ParentEntity]
GO
