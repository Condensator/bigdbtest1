CREATE TYPE [dbo].[MaturityMonitorActivityType] AS TABLE(
	[DocumentAssigned] [bit] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[DocumentGenerate] [bit] NOT NULL,
	[Deadline] [date] NULL,
	[DocumentSentDate] [date] NULL,
	[FollowUpDate] [date] NULL,
	[MaturityActivityTypeId] [bigint] NULL,
	[MaturityMonitorId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
