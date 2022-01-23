CREATE TYPE [dbo].[NotificationRecipientConfig] AS TABLE(
	[IsActive] [bit] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[NotifyTxnSubscribersOnly] [bit] NOT NULL,
	[Condition] [nvarchar](1000) COLLATE Latin1_General_CI_AS NULL,
	[OverrideEmailNotification] [bit] NOT NULL,
	[RecipientType] [nvarchar](21) COLLATE Latin1_General_CI_AS NULL,
	[UserExpression] [nvarchar](1000) COLLATE Latin1_General_CI_AS NULL,
	[IsMultipleUser] [bit] NOT NULL,
	[ExternalEmailSelectionSQL] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[FromEmail] [nvarchar](70) COLLATE Latin1_General_CI_AS NULL,
	[FromEmailExpression] [nvarchar](1000) COLLATE Latin1_General_CI_AS NULL,
	[EmailTemplateId] [bigint] NULL,
	[UserId] [bigint] NULL,
	[UserGroupId] [bigint] NULL,
	[NotificationConfigId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
