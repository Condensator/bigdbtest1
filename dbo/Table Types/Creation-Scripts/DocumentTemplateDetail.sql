CREATE TYPE [dbo].[DocumentTemplateDetail] AS TABLE(
	[Template_Source] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[Template_Type] [nvarchar](5) COLLATE Latin1_General_CI_AS NULL,
	[Template_Content] [varbinary](82) NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ExternalTemplateKey] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[LanguageId] [bigint] NOT NULL,
	[DocumentTemplateId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
