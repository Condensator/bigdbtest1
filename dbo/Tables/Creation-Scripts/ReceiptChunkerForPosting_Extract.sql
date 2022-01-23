SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ReceiptChunkerForPosting_Extract](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[JobStepInstanceId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[PrePostingStartTime] [datetimeoffset](7) NULL,
	[PrePostingEndTime] [datetimeoffset](7) NULL,
	[PrePostingBatchStatus] [nvarchar](10) COLLATE Latin1_General_CI_AS NULL,
	[PrePostingTaskChunkServiceInstanceId] [bigint] NULL,
	[PostingStartTime] [datetimeoffset](7) NULL,
	[PostingEndTime] [datetimeoffset](7) NULL,
	[PostingBatchStatus] [nvarchar](10) COLLATE Latin1_General_CI_AS NULL,
	[PostingTaskChunkServiceInstanceId] [bigint] NULL,
	[SourceModule] [nvarchar](21) COLLATE Latin1_General_CI_AS NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
