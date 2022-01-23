CREATE TYPE [dbo].[AssetSalesTradeIn] AS TABLE(
	[NetValue_Amount] [decimal](16, 2) NOT NULL,
	[NetValue_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[IsActive] [bit] NOT NULL,
	[VATType] [nvarchar](7) COLLATE Latin1_General_CI_AS NULL,
	[ProjectedVATAmount_Amount] [decimal](16, 2) NULL,
	[ProjectedVATAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[AssetId] [bigint] NOT NULL,
	[TaxCodeId] [bigint] NULL,
	[TaxTypeId] [bigint] NULL,
	[TaxCodeRateId] [bigint] NULL,
	[AssetSaleId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
