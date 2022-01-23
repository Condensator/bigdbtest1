SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PreQuoteLeaseDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[DiscountRate] [decimal](8, 4) NULL,
	[PayoffAmount_Amount] [decimal](16, 2) NOT NULL,
	[PayoffAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[BuyoutAmount_Amount] [decimal](16, 2) NOT NULL,
	[BuyoutAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[OTPRent_Amount] [decimal](16, 2) NOT NULL,
	[OTPRent_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[FMV_Amount] [decimal](16, 2) NOT NULL,
	[FMV_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[LateFee_Amount] [decimal](16, 2) NOT NULL,
	[LateFee_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Maintenance_Amount] [decimal](16, 2) NOT NULL,
	[Maintenance_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[PropertyTax_Amount] [decimal](16, 2) NOT NULL,
	[PropertyTax_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[OtherCharge_Amount] [decimal](16, 2) NOT NULL,
	[OtherCharge_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[EstimatedPropertyTax_Amount] [decimal](16, 2) NOT NULL,
	[EstimatedPropertyTax_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[AssetValuation_Amount] [decimal](16, 2) NOT NULL,
	[AssetValuation_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[TerminationOptionId] [bigint] NULL,
	[PreQuoteLeaseId] [bigint] NOT NULL,
	[PreQuoteId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[IsComputationPerformed] [bit] NOT NULL,
	[IsSalesTaxAssessed] [bit] NOT NULL,
	[PayoffSalesTax_Amount] [decimal](16, 2) NOT NULL,
	[PayoffSalesTax_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[BuyoutSalesTax_Amount] [decimal](16, 2) NOT NULL,
	[BuyoutSalesTax_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[PreQuoteLeaseDetails]  WITH CHECK ADD  CONSTRAINT [EPreQuote_PreQuoteLeaseDetails] FOREIGN KEY([PreQuoteId])
REFERENCES [dbo].[PreQuotes] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[PreQuoteLeaseDetails] CHECK CONSTRAINT [EPreQuote_PreQuoteLeaseDetails]
GO
ALTER TABLE [dbo].[PreQuoteLeaseDetails]  WITH CHECK ADD  CONSTRAINT [EPreQuoteLeaseDetail_PreQuoteLease] FOREIGN KEY([PreQuoteLeaseId])
REFERENCES [dbo].[PreQuoteLeases] ([Id])
GO
ALTER TABLE [dbo].[PreQuoteLeaseDetails] CHECK CONSTRAINT [EPreQuoteLeaseDetail_PreQuoteLease]
GO
ALTER TABLE [dbo].[PreQuoteLeaseDetails]  WITH CHECK ADD  CONSTRAINT [EPreQuoteLeaseDetail_TerminationOption] FOREIGN KEY([TerminationOptionId])
REFERENCES [dbo].[PayoffTerminationOptions] ([Id])
GO
ALTER TABLE [dbo].[PreQuoteLeaseDetails] CHECK CONSTRAINT [EPreQuoteLeaseDetail_TerminationOption]
GO
