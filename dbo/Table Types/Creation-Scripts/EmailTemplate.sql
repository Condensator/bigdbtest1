CREATE TYPE [dbo].[EmailTemplate] AS TABLE(
	[Name] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[Subject] [nvarchar](500) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsTagBased] [bit] NOT NULL,
	[BodyText] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[BodyTemplate_Source] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[BodyTemplate_Type] [nvarchar](5) COLLATE Latin1_General_CI_AS NULL,
	[BodyTemplate_Content] [varbinary](82) NULL,
	[IsActive] [bit] NOT NULL,
	[EmailTemplateEntityConfigId] [bigint] NULL,
	[EmailTemplateTypeId] [bigint] NOT NULL,
	[PortfolioId] [bigint] NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
