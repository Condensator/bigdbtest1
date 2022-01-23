CREATE TYPE [dbo].[ReceiptChunkerForPosting_Extract] AS TABLE(
	[PrePostingStartTime] [datetimeoffset](7) NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[PrePostingEndTime] [datetimeoffset](7) NULL,
	[PrePostingBatchStatus] [nvarchar](10) COLLATE Latin1_General_CI_AS NULL,
	[PrePostingTaskChunkServiceInstanceId] [bigint] NULL,
	[PostingStartTime] [datetimeoffset](7) NULL,
	[PostingEndTime] [datetimeoffset](7) NULL,
	[PostingBatchStatus] [nvarchar](10) COLLATE Latin1_General_CI_AS NULL,
	[PostingTaskChunkServiceInstanceId] [bigint] NULL,
	[JobStepInstanceId] [bigint] NULL,
	[SourceModule] [nvarchar](21) COLLATE Latin1_General_CI_AS NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
