CREATE TYPE [dbo].[NachaFileFormatConfig] AS TABLE(
	[FieldName] [nvarchar](50) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[Value] [nvarchar](50) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[FileType] [nvarchar](9) COLLATE Latin1_General_CI_AS NOT NULL,
	[FileRecordType] [nvarchar](17) COLLATE Latin1_General_CI_AS NOT NULL,
	[Description] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
