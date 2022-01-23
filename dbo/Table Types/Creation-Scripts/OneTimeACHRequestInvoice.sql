CREATE TYPE [dbo].[OneTimeACHRequestInvoice] AS TABLE(
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[IsActive] [bit] NOT NULL,
	[PaymentDate] [date] NULL,
	[AmountToPay_Amount] [decimal](16, 2) NOT NULL,
	[AmountToPay_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Status] [nvarchar](18) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsStatementInvoice] [bit] NOT NULL,
	[ReceivableInvoiceId] [bigint] NOT NULL,
	[OneTimeACHId] [bigint] NULL,
	[OneTimeACHRequestId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
