CREATE TYPE [dbo].[DocumentTemplate] AS TABLE(
	[Name] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[IsLanguageApplicable] [bit] NOT NULL,
	[IsDefault] [bit] NOT NULL,
	[GeneratedTemplate_Source] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[GeneratedTemplate_Type] [nvarchar](5) COLLATE Latin1_General_CI_AS NULL,
	[GeneratedTemplate_Content] [varbinary](82) NULL,
	[RelatedEntityId] [bigint] NULL,
	[IsActive] [bit] NOT NULL,
	[IsExpressionBased] [bit] NOT NULL,
	[EnabledForESignature] [bit] NOT NULL,
	[ScriptId] [bigint] NULL,
	[DocumentTypeId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
