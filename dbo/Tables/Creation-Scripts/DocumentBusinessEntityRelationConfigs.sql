SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DocumentBusinessEntityRelationConfigs](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[RelationshipType] [nvarchar](9) COLLATE Latin1_General_CI_AS NOT NULL,
	[NavigationPath] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[QuerySource] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[TextProperty] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[GridName] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RootEntityId] [bigint] NOT NULL,
	[RelatedEntityId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[DocumentBusinessEntityRelationConfigs]  WITH CHECK ADD  CONSTRAINT [EDocumentBusinessEntityRelationConfig_RelatedEntity] FOREIGN KEY([RelatedEntityId])
REFERENCES [dbo].[DocumentBusinessEntityConfigs] ([Id])
GO
ALTER TABLE [dbo].[DocumentBusinessEntityRelationConfigs] CHECK CONSTRAINT [EDocumentBusinessEntityRelationConfig_RelatedEntity]
GO
ALTER TABLE [dbo].[DocumentBusinessEntityRelationConfigs]  WITH CHECK ADD  CONSTRAINT [EDocumentBusinessEntityRelationConfig_RootEntity] FOREIGN KEY([RootEntityId])
REFERENCES [dbo].[DocumentEntityConfigs] ([Id])
GO
ALTER TABLE [dbo].[DocumentBusinessEntityRelationConfigs] CHECK CONSTRAINT [EDocumentBusinessEntityRelationConfig_RootEntity]
GO
