CREATE TYPE [dbo].[InvoiceChunkStatus_Extract] AS TABLE(
	[RunJobStepInstanceId] [bigint] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ChunkNumber] [int] NOT NULL,
	[InvoicingStatus] [nvarchar](10) COLLATE Latin1_General_CI_AS NOT NULL,
	[TaskChunkServiceInstanceId] [bigint] NULL,
	[IsReceivableInvoiceProcessed] [bit] NOT NULL,
	[IsStatementInvoiceProcessed] [bit] NOT NULL,
	[IsExtractionProcessed] [bit] NOT NULL,
	[IsFileGenerated] [bit] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
