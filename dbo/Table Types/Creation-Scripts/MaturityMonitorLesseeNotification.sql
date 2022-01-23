CREATE TYPE [dbo].[MaturityMonitorLesseeNotification] AS TABLE(
	[NotificationNumber] [int] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[NoticeReceivedDate] [date] NOT NULL,
	[ContractOptionSelected] [nvarchar](20) COLLATE Latin1_General_CI_AS NOT NULL,
	[Response] [nvarchar](7) COLLATE Latin1_General_CI_AS NOT NULL,
	[Status] [nvarchar](8) COLLATE Latin1_General_CI_AS NOT NULL,
	[EffectiveMaturityDate] [date] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[RenewalDetailId] [bigint] NULL,
	[ContractOptionId] [bigint] NULL,
	[MaturityMonitorId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
