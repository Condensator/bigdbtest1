CREATE TYPE [dbo].[NotificationAttachment] AS TABLE(
	[Attachment_Source] [nvarchar](250) COLLATE Latin1_General_CI_AS NOT NULL,
	[Attachment_Type] [nvarchar](5) COLLATE Latin1_General_CI_AS NOT NULL,
	[Attachment_Content] [varbinary](82) NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[NotificationId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
