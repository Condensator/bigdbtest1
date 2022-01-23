CREATE TYPE [dbo].[EventInstance] AS TABLE(
	[EntityName] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[EntityId] [bigint] NULL,
	[EntitySummary] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[Status] [nvarchar](10) COLLATE Latin1_General_CI_AS NOT NULL,
	[CorrelationId] [uniqueidentifier] NOT NULL,
	[EventArg] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[IsExternalCall] [bit] NOT NULL,
	[IsMigrationCall] [bit] NOT NULL,
	[IsWebServiceCall] [bit] NOT NULL,
	[EventConfigId] [bigint] NOT NULL,
	[SubmittedUserId] [bigint] NOT NULL,
	[BusinessUnitId] [bigint] NOT NULL,
	[JobServiceId] [bigint] NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
