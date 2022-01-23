CREATE TYPE [dbo].[WorkItemHistory] AS TABLE(
	[Reason] [nvarchar](19) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[Status] [nvarchar](10) COLLATE Latin1_General_CI_AS NOT NULL,
	[StartDate] [datetimeoffset](7) NULL,
	[DueDate] [datetimeoffset](7) NULL,
	[WorkItemId] [bigint] NOT NULL,
	[OwnerUserId] [bigint] NULL,
	[PerformedById] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
