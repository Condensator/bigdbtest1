CREATE TYPE [dbo].[Attachment] AS TABLE(
	[File_Source] [nvarchar](250) COLLATE Latin1_General_CI_AS NOT NULL,
	[File_Type] [nvarchar](5) COLLATE Latin1_General_CI_AS NOT NULL,
	[File_Content] [varbinary](82) NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[Description] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[AttachedDate] [date] NOT NULL,
	[AttachedById] [bigint] NOT NULL,
	[SourceId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
