CREATE TYPE [dbo].[ApplicationTrace] AS TABLE(
	[CorrelationId] [nvarchar](36) COLLATE Latin1_General_CI_AS NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[TraceFile_Source] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[TraceFile_Type] [nvarchar](5) COLLATE Latin1_General_CI_AS NULL,
	[TraceFile_Content] [varbinary](82) NULL,
	[Source] [nvarchar](14) COLLATE Latin1_General_CI_AS NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
