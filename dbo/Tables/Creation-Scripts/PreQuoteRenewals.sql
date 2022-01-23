SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PreQuoteRenewals](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsRenewalAccepted] [bit] NOT NULL,
	[Term] [int] NULL,
	[RenewalType] [nvarchar](14) COLLATE Latin1_General_CI_AS NULL,
	[SuggestedPrice_Amount] [decimal](16, 2) NULL,
	[SuggestedPrice_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[Price_Amount] [decimal](16, 2) NULL,
	[Price_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[PaymentAmount_Amount] [decimal](16, 2) NULL,
	[PaymentAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[ServiceAmount_Amount] [decimal](16, 2) NULL,
	[ServiceAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[PaymentFrequency] [nvarchar](13) COLLATE Latin1_General_CI_AS NULL,
	[InterestRate] [decimal](10, 6) NULL,
	[ResidualValue_Amount] [decimal](16, 2) NULL,
	[ResidualValue_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[ExistingNBV_Amount] [decimal](16, 2) NULL,
	[ExistingNBV_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[UpgradeRenewalPrice_Amount] [decimal](16, 2) NULL,
	[UpgradeRenewalPrice_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[UpgradeRenewalDollar_Amount] [decimal](16, 2) NULL,
	[UpgradeRenewalDollar_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[UpgradeRenewalPMT_Amount] [decimal](16, 2) NULL,
	[UpgradeRenewalPMT_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[UpgradeRenewalService_Amount] [decimal](16, 2) NULL,
	[UpgradeRenewalService_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[UpgradeRenewalRV_Amount] [decimal](16, 2) NULL,
	[UpgradeRenewalRV_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[TotalPrice_Amount] [decimal](16, 2) NULL,
	[TotalPrice_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[TotalPayment_Amount] [decimal](16, 2) NULL,
	[TotalPayment_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[TotalService_Amount] [decimal](16, 2) NULL,
	[TotalService_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ContractId] [bigint] NULL,
	[AssetCatalogId] [bigint] NULL,
	[PreQuoteId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[PreQuoteRenewals]  WITH CHECK ADD  CONSTRAINT [EPreQuote_PreQuoteRenewals] FOREIGN KEY([PreQuoteId])
REFERENCES [dbo].[PreQuotes] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[PreQuoteRenewals] CHECK CONSTRAINT [EPreQuote_PreQuoteRenewals]
GO
ALTER TABLE [dbo].[PreQuoteRenewals]  WITH CHECK ADD  CONSTRAINT [EPreQuoteRenewal_AssetCatalog] FOREIGN KEY([AssetCatalogId])
REFERENCES [dbo].[AssetCatalogs] ([Id])
GO
ALTER TABLE [dbo].[PreQuoteRenewals] CHECK CONSTRAINT [EPreQuoteRenewal_AssetCatalog]
GO
ALTER TABLE [dbo].[PreQuoteRenewals]  WITH CHECK ADD  CONSTRAINT [EPreQuoteRenewal_Contract] FOREIGN KEY([ContractId])
REFERENCES [dbo].[Contracts] ([Id])
GO
ALTER TABLE [dbo].[PreQuoteRenewals] CHECK CONSTRAINT [EPreQuoteRenewal_Contract]
GO
