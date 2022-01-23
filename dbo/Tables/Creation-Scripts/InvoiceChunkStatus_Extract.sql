SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[InvoiceChunkStatus_Extract](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RunJobStepInstanceId] [bigint] NOT NULL,
	[ChunkNumber] [int] NOT NULL,
	[InvoicingStatus] [nvarchar](10) COLLATE Latin1_General_CI_AS NOT NULL,
	[TaskChunkServiceInstanceId] [bigint] NULL,
	[IsReceivableInvoiceProcessed] [bit] NOT NULL,
	[IsStatementInvoiceProcessed] [bit] NOT NULL,
	[IsExtractionProcessed] [bit] NOT NULL,
	[IsFileGenerated] [bit] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
