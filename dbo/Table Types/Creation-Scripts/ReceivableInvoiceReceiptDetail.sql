CREATE TYPE [dbo].[ReceivableInvoiceReceiptDetail] AS TABLE(
	[ReceivedDate] [date] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[IsActive] [bit] NOT NULL,
	[AmountApplied_Amount] [decimal](16, 2) NOT NULL,
	[AmountApplied_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[TaxApplied_Amount] [decimal](16, 2) NOT NULL,
	[TaxApplied_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[ReceiptId] [bigint] NOT NULL,
	[ReceivableInvoiceId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO