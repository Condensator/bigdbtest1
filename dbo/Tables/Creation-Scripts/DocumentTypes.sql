SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DocumentTypes](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[DocumentDirection] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Description] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[Category] [nvarchar](14) COLLATE Latin1_General_CI_AS NULL,
	[Classification] [nvarchar](10) COLLATE Latin1_General_CI_AS NOT NULL,
	[ViewableAtRelatedEntities] [bit] NOT NULL,
	[AllowDuplicate] [bit] NOT NULL,
	[DefaultPermission] [nvarchar](1) COLLATE Latin1_General_CI_AS NOT NULL,
	[ManualEntitySelectionNeeded] [bit] NOT NULL,
	[DocumentTitleRequired] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[IsReadyToUse] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[EntityId] [bigint] NOT NULL,
	[BusinessEntityId] [bigint] NULL,
	[RelatedDocTypeId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[CreationAllowed] [nvarchar](7) COLLATE Latin1_General_CI_AS NOT NULL,
	[GenerationAllowedExpression] [nvarchar](1000) COLLATE Latin1_General_CI_AS NULL,
	[IsCoverLetter] [bit] NOT NULL,
	[IsRetention] [bit] NOT NULL,
	[DefaultTitle] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[PortfolioId] [bigint] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[DocumentTypes]  WITH CHECK ADD  CONSTRAINT [EDocumentType_BusinessEntity] FOREIGN KEY([BusinessEntityId])
REFERENCES [dbo].[DocumentBusinessEntityConfigs] ([Id])
GO
ALTER TABLE [dbo].[DocumentTypes] CHECK CONSTRAINT [EDocumentType_BusinessEntity]
GO
ALTER TABLE [dbo].[DocumentTypes]  WITH CHECK ADD  CONSTRAINT [EDocumentType_Entity] FOREIGN KEY([EntityId])
REFERENCES [dbo].[DocumentEntityConfigs] ([Id])
GO
ALTER TABLE [dbo].[DocumentTypes] CHECK CONSTRAINT [EDocumentType_Entity]
GO
ALTER TABLE [dbo].[DocumentTypes]  WITH CHECK ADD  CONSTRAINT [EDocumentType_Portfolio] FOREIGN KEY([PortfolioId])
REFERENCES [dbo].[Portfolios] ([Id])
GO
ALTER TABLE [dbo].[DocumentTypes] CHECK CONSTRAINT [EDocumentType_Portfolio]
GO
ALTER TABLE [dbo].[DocumentTypes]  WITH CHECK ADD  CONSTRAINT [EDocumentType_RelatedDocType] FOREIGN KEY([RelatedDocTypeId])
REFERENCES [dbo].[DocumentTypes] ([Id])
GO
ALTER TABLE [dbo].[DocumentTypes] CHECK CONSTRAINT [EDocumentType_RelatedDocType]
GO
