CREATE TYPE [dbo].[SystemConfigFile] AS TABLE(
	[Name] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[IsActive] [bit] NOT NULL,
	[File_Source] [nvarchar](250) COLLATE Latin1_General_CI_AS NOT NULL,
	[File_Type] [nvarchar](5) COLLATE Latin1_General_CI_AS NOT NULL,
	[File_Content] [varbinary](82) NOT NULL,
	[ConfigType] [nvarchar](23) COLLATE Latin1_General_CI_AS NULL,
	[Description] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
