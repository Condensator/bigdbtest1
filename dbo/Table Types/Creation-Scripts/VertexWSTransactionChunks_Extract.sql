CREATE TYPE [dbo].[VertexWSTransactionChunks_Extract] AS TABLE(
	[BatchStatus] [nvarchar](10) COLLATE Latin1_General_CI_AS NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[TaskChunkServiceInstanceId] [bigint] NULL,
	[JobStepInstanceId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
