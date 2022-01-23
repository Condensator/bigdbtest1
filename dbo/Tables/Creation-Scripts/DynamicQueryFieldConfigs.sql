SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DynamicQueryFieldConfigs](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[FieldName] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[MetaModelFieldName] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[FieldAlias] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[FieldType] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[DynamicQueryTypeConfigId] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RowVersion] [timestamp] NOT NULL,
	[TextQuerySource] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[DynamicQueryFieldConfigs]  WITH CHECK ADD  CONSTRAINT [EDynamicQueryTypeConfig_DynamicQueryFieldConfigs] FOREIGN KEY([DynamicQueryTypeConfigId])
REFERENCES [dbo].[DynamicQueryTypeConfigs] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[DynamicQueryFieldConfigs] CHECK CONSTRAINT [EDynamicQueryTypeConfig_DynamicQueryFieldConfigs]
GO
