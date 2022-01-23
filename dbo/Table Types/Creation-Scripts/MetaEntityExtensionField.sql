CREATE TYPE [dbo].[MetaEntityExtensionField] AS TABLE(
	[Name] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[DataType] [nvarchar](250) COLLATE Latin1_General_CI_AS NOT NULL,
	[Label] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[Description] [nvarchar](500) COLLATE Latin1_General_CI_AS NOT NULL,
	[Nullable] [bit] NOT NULL,
	[Enabled] [bit] NOT NULL,
	[Visible] [bit] NOT NULL,
	[DefaultValue] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[IsAlteration] [bit] NOT NULL,
	[ShowOnBrowseForm] [bit] NOT NULL,
	[MetaEntityExtensionId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
