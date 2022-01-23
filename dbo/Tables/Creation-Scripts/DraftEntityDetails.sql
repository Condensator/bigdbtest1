SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DraftEntityDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Data] [nvarchar](max) COLLATE Latin1_General_CI_AS NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[LookupKey] [nvarchar](500) COLLATE Latin1_General_CI_AS NOT NULL,
	[Status] [nvarchar](17) COLLATE Latin1_General_CI_AS NOT NULL,
	[ValidationMessages] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[EntityConversionErrors] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[TaskChunkServiceInstanceId] [bigint] NULL,
	[DraftEntityBatchId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[JobCorrelationId] [nvarchar](36) COLLATE Latin1_General_CI_AS NULL,
	[CreatedMode] [nvarchar](12) COLLATE Latin1_General_CI_AS NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[DraftEntityDetails]  WITH CHECK ADD  CONSTRAINT [EDraftEntityBatch_DraftEntityDetails] FOREIGN KEY([DraftEntityBatchId])
REFERENCES [dbo].[DraftEntityBatches] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[DraftEntityDetails] CHECK CONSTRAINT [EDraftEntityBatch_DraftEntityDetails]
GO
