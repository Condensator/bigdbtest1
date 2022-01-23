CREATE TYPE [dbo].[ACHRunDetail] AS TABLE(
	[EntityId] [bigint] NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[TraceNumber] [nvarchar](20) COLLATE Latin1_General_CI_AS NULL,
	[IsReversed] [bit] NOT NULL,
	[IsPending] [bit] NOT NULL,
	[ACHRunFileId] [bigint] NULL,
	[ACHRunId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
