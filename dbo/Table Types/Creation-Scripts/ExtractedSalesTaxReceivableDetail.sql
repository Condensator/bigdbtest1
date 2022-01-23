CREATE TYPE [dbo].[ExtractedSalesTaxReceivableDetail] AS TABLE(
	[ContractId] [bigint] NULL,
	[LegalEntityName] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[ReceivableId] [bigint] NULL,
	[ReceivableDetailId] [bigint] NULL,
	[ReceivableDueDate] [date] NULL,
	[AssetId] [bigint] NULL,
	[InvalidErrorCode] [nvarchar](4) COLLATE Latin1_General_CI_AS NULL
)
GO
