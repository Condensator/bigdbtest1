CREATE TYPE [dbo].[JobServiceDetail] AS TABLE(
	[StartTime] [datetimeoffset](7) NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[StopTime] [datetimeoffset](7) NULL,
	[JobServiceId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
