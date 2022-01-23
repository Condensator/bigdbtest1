CREATE TYPE [dbo].[NonAccrualChunks_Extract] AS TABLE(
	[ChunkStatus] [nvarchar](19) COLLATE Latin1_General_CI_AS NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[TaskChunkServiceInstanceId] [bigint] NULL,
	[JobStepInstanceId] [bigint] NOT NULL,
	[ChunkNumber] [bigint] NOT NULL,
	[StartTime] [datetimeoffset](7) NULL,
	[EndTime] [datetimeoffset](7) NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
