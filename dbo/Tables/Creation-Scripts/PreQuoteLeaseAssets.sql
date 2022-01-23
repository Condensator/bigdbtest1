SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PreQuoteLeaseAssets](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[AssetValuation_Amount] [decimal](16, 2) NOT NULL,
	[AssetValuation_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Status] [nvarchar](21) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[PreQuoteLeaseId] [bigint] NOT NULL,
	[LeaseAssetId] [bigint] NOT NULL,
	[PreQuoteId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[NBVAsOfEffectiveDate_Amount] [decimal](16, 2) NOT NULL,
	[NBVAsOfEffectiveDate_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[NBV_Amount] [decimal](16, 2) NOT NULL,
	[NBV_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[PayoffAmount_Amount] [decimal](16, 2) NOT NULL,
	[PayoffAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[BuyoutAmount_Amount] [decimal](16, 2) NOT NULL,
	[BuyoutAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[SalesTaxRate] [decimal](9, 5) NOT NULL,
	[BookedResidual_Amount] [decimal](16, 2) NOT NULL,
	[BookedResidual_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[FMV_Amount] [decimal](16, 2) NOT NULL,
	[FMV_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[DepreciationTerm] [decimal](4, 1) NOT NULL,
	[UsefulLife] [int] NULL,
	[EstimatedPropertyTax_Amount] [decimal](16, 2) NOT NULL,
	[EstimatedPropertyTax_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[BuyoutSalesTaxRate] [decimal](9, 5) NOT NULL,
	[CalculatedNBV_Amount] [decimal](16, 2) NOT NULL,
	[CalculatedNBV_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[OutstandingRentalBilled_Amount] [decimal](16, 2) NOT NULL,
	[OutstandingRentalBilled_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[OutstandingRentalsUnbilled_Amount] [decimal](16, 2) NOT NULL,
	[OutstandingRentalsUnbilled_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[RemainingRentals_Amount] [decimal](16, 2) NOT NULL,
	[RemainingRentals_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[PreQuoteLeaseAssets]  WITH CHECK ADD  CONSTRAINT [EPreQuote_PreQuoteLeaseAssets] FOREIGN KEY([PreQuoteId])
REFERENCES [dbo].[PreQuotes] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[PreQuoteLeaseAssets] CHECK CONSTRAINT [EPreQuote_PreQuoteLeaseAssets]
GO
ALTER TABLE [dbo].[PreQuoteLeaseAssets]  WITH CHECK ADD  CONSTRAINT [EPreQuoteLeaseAsset_LeaseAsset] FOREIGN KEY([LeaseAssetId])
REFERENCES [dbo].[LeaseAssets] ([Id])
GO
ALTER TABLE [dbo].[PreQuoteLeaseAssets] CHECK CONSTRAINT [EPreQuoteLeaseAsset_LeaseAsset]
GO
ALTER TABLE [dbo].[PreQuoteLeaseAssets]  WITH CHECK ADD  CONSTRAINT [EPreQuoteLeaseAsset_PreQuoteLease] FOREIGN KEY([PreQuoteLeaseId])
REFERENCES [dbo].[PreQuoteLeases] ([Id])
GO
ALTER TABLE [dbo].[PreQuoteLeaseAssets] CHECK CONSTRAINT [EPreQuoteLeaseAsset_PreQuoteLease]
GO
