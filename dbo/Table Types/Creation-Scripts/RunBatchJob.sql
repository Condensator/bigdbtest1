CREATE TYPE [dbo].[RunBatchJob] AS TABLE(
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
