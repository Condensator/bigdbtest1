CREATE TYPE [dbo].[NetValueUpdateInfo] AS TABLE(
	[SourceId] [bigint] NULL,
	[NetValue] [decimal](18, 0) NULL,
	[IsCleared] [bit] NULL
)
GO
