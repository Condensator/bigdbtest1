CREATE TYPE [dbo].[DSLReceiptHistory] AS TABLE(
	[AmountPosted_Amount] [decimal](16, 2) NULL,
	[AmountPosted_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ReceivedDate] [date] NULL,
	[IsActive] [bit] NOT NULL,
	[InvoiceId] [bigint] NULL,
	[ReceivableDetailId] [bigint] NULL,
	[ReceiptId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
