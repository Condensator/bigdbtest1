CREATE TYPE [dbo].[BillToInvoiceFormat] AS TABLE(
	[ReceivableCategory] [nvarchar](16) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ReceivableCategoryId] [bigint] NULL,
	[InvoiceOutputFormat] [nvarchar](5) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[InvoiceFormatId] [bigint] NOT NULL,
	[VATInvoiceFormatId] [bigint] NULL,
	[InvoiceTypeLabelId] [bigint] NOT NULL,
	[InvoiceEmailTemplateId] [bigint] NULL,
	[BillToId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
