CREATE TYPE [dbo].[BulkUploadInstance] AS TABLE(
	[Name] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ImportedFile_Source] [nvarchar](250) COLLATE Latin1_General_CI_AS NOT NULL,
	[ImportedFile_Type] [nvarchar](5) COLLATE Latin1_General_CI_AS NOT NULL,
	[ImportedFile_Content] [varbinary](82) NOT NULL,
	[JobInstanceId] [bigint] NULL,
	[ProfileId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
