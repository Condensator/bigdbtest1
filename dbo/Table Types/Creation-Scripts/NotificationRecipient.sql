CREATE TYPE [dbo].[NotificationRecipient] AS TABLE(
	[ToEmailId] [nvarchar](1000) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[CcEmailId] [nvarchar](1000) COLLATE Latin1_General_CI_AS NULL,
	[BccEmailId] [nvarchar](1000) COLLATE Latin1_General_CI_AS NULL,
	[IsFlaggedForSending] [bit] NOT NULL,
	[UserId] [bigint] NULL,
	[UserGroupId] [bigint] NULL,
	[ExternalRecipientId] [bigint] NULL,
	[NotificationId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
