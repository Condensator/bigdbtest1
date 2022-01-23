CREATE TYPE [dbo].[DynamicQueryFieldConfig] AS TABLE(
	[FieldName] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[MetaModelFieldName] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[FieldAlias] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[FieldType] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[TextQuerySource] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[DynamicQueryTypeConfigId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
