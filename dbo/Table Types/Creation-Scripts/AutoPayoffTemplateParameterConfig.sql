CREATE TYPE [dbo].[AutoPayoffTemplateParameterConfig] AS TABLE(
	[Name] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[IsActive] [bit] NOT NULL,
	[Description] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[Type] [nvarchar](15) COLLATE Latin1_General_CI_AS NOT NULL,
	[Collection] [bit] NOT NULL,
	[DataSource] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[QualificationQuery] [nvarchar](250) COLLATE Latin1_General_CI_AS NOT NULL,
	[Order] [int] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
