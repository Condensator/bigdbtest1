CREATE TYPE [dbo].[ACHFileDetails] AS TABLE(
	[EntryDetailLineNumber] [bigint] NULL,
	[ReturnReasonCodeLineNumber] [bigint] NULL,
	[ReceiptReversalReasonCode] [nvarchar](80) COLLATE Latin1_General_CI_AS NULL,
	[ReturnFileReceiptAmount] [decimal](16, 2) NULL,
	[TraceNumber] [nvarchar](20) COLLATE Latin1_General_CI_AS NULL
)
GO
