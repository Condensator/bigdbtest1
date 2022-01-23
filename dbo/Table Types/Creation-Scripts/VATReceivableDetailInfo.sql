CREATE TYPE [dbo].[VATReceivableDetailInfo] AS TABLE(
	[ReceivableDetailId] [bigint] NULL,
	[ReceivableDueDate] [date] NULL,
	[SourceId] [bigint] NULL,
	[SourceTable] [nvarchar](10) COLLATE Latin1_General_CI_AS NULL,
	[EntityType] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[ContractId] [bigint] NULL,
	[AssetId] [bigint] NULL,
	[ReceivableDetailAmount] [decimal](18, 2) NULL,
	[Currency] [nvarchar](80) COLLATE Latin1_General_CI_AS NULL,
	[InvoiceNumber] [nvarchar](80) COLLATE Latin1_General_CI_AS NULL,
	[ReceivableCodeId] [bigint] NULL
)
GO
