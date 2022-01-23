SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[VATReceivableLocationDetail_Extract](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[ReceivableDetailId] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[AssetId] [bigint] NULL,
	[JobStepInstanceId] [bigint] NOT NULL,
	[ReceivableTypeId] [bigint] NOT NULL,
	[TaxLevel] [nvarchar](7) COLLATE Latin1_General_CI_AS NOT NULL,
	[BuyerLocationId] [bigint] NOT NULL,
	[SellerLocationId] [bigint] NOT NULL,
	[TaxReceivableTypeId] [bigint] NULL,
	[PayableTypeId] [bigint] NULL,
	[TaxAssetTypeId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[TaxRemittanceType] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[BuyerLocation] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[SellerLocation] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[TaxAssetType] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[TaxReceivableType] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[IsCapitalizedUpfront] [bit] NOT NULL,
	[IsReceivableCodeTaxExempt] [bit] NOT NULL,
	[ReceivableId] [bigint] NULL,
	[ReceivableDueDate] [date] NULL,
	[CustomerId] [bigint] NULL,
	[LegalEntityId] [bigint] NULL,
	[BuyerTaxRegistrationId] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[SellerTaxRegistrationId] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[BasisAmount] [decimal](16, 2) NOT NULL,
	[BasisAmountCurrency] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
