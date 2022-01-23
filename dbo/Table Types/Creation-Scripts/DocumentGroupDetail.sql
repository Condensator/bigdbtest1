CREATE TYPE [dbo].[DocumentGroupDetail] AS TABLE(
	[IsMandatory] [bit] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ForceRegenerate] [bit] NOT NULL,
	[AttachmentRequired] [bit] NOT NULL,
	[DefaultTemplateExpression] [nvarchar](1000) COLLATE Latin1_General_CI_AS NULL,
	[AutoGenerate] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[GenerationOrder] [bigint] NOT NULL,
	[DocumentTypeId] [bigint] NOT NULL,
	[DefaultTemplateId] [bigint] NULL,
	[DocumentGroupId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
