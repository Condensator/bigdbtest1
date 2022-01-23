CREATE TYPE [dbo].[NotificationConfig] AS TABLE(
	[Category] [nvarchar](12) COLLATE Latin1_General_CI_AS NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[Operation] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[EmailNotification] [bit] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
