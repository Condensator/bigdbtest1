SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[EmailTemplates](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[Subject] [nvarchar](500) COLLATE Latin1_General_CI_AS NOT NULL,
	[BodyText] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[BodyTemplate_Source] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[BodyTemplate_Type] [nvarchar](5) COLLATE Latin1_General_CI_AS NULL,
	[BodyTemplate_Content] [varbinary](82) NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RowVersion] [timestamp] NOT NULL,
	[EmailTemplateEntityConfigId] [bigint] NULL,
	[EmailTemplateTypeId] [bigint] NOT NULL,
	[PortfolioId] [bigint] NULL,
	[IsTagBased] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[EmailTemplates]  WITH CHECK ADD  CONSTRAINT [EEmailTemplate_EmailTemplateEntityConfig] FOREIGN KEY([EmailTemplateEntityConfigId])
REFERENCES [dbo].[EmailTemplateEntityConfigs] ([Id])
GO
ALTER TABLE [dbo].[EmailTemplates] CHECK CONSTRAINT [EEmailTemplate_EmailTemplateEntityConfig]
GO
ALTER TABLE [dbo].[EmailTemplates]  WITH CHECK ADD  CONSTRAINT [EEmailTemplate_EmailTemplateType] FOREIGN KEY([EmailTemplateTypeId])
REFERENCES [dbo].[EmailTemplateTypes] ([Id])
GO
ALTER TABLE [dbo].[EmailTemplates] CHECK CONSTRAINT [EEmailTemplate_EmailTemplateType]
GO
ALTER TABLE [dbo].[EmailTemplates]  WITH CHECK ADD  CONSTRAINT [EEmailTemplate_Portfolio] FOREIGN KEY([PortfolioId])
REFERENCES [dbo].[Portfolios] ([Id])
GO
ALTER TABLE [dbo].[EmailTemplates] CHECK CONSTRAINT [EEmailTemplate_Portfolio]
GO
