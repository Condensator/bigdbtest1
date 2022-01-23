CREATE TYPE [dbo].[PayoffInvoice] AS TABLE(
	[ReferenceNumber] [int] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[InvoiceFile_Source] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[InvoiceFile_Type] [nvarchar](5) COLLATE Latin1_General_CI_AS NULL,
	[InvoiceFile_Content] [varbinary](82) NULL,
	[IsActive] [bit] NOT NULL,
	[InvoiceId] [bigint] NULL,
	[PayoffId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
