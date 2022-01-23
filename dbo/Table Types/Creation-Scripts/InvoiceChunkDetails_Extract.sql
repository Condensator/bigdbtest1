CREATE TYPE [dbo].[InvoiceChunkDetails_Extract] AS TABLE(
	[JobStepInstanceId] [bigint] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ChunkNumber] [int] NULL,
	[BillToId] [bigint] NOT NULL,
	[GenerateStatementInvoice] [bit] NOT NULL,
	[ReceivableDetailsCount] [int] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
