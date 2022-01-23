CREATE TYPE [dbo].[DashboardAttachment] AS TABLE(
	[DocumentName] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[Title] [nvarchar](20) COLLATE Latin1_General_CI_AS NOT NULL,
	[DocumentDescription] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[Attachment_Source] [nvarchar](250) COLLATE Latin1_General_CI_AS NOT NULL,
	[Attachment_Type] [nvarchar](5) COLLATE Latin1_General_CI_AS NOT NULL,
	[Attachment_Content] [varbinary](82) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[DashboardProfileId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
