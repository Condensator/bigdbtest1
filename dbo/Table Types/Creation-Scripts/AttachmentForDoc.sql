CREATE TYPE [dbo].[AttachmentForDoc] AS TABLE(
	[GeneratedRawFile_Source] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[GeneratedRawFile_Type] [nvarchar](5) COLLATE Latin1_General_CI_AS NULL,
	[GeneratedRawFile_Content] [varbinary](82) NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[IsGenerated] [bit] NOT NULL,
	[IsPacked] [bit] NOT NULL,
	[IsSample] [bit] NOT NULL,
	[AttachmentId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
