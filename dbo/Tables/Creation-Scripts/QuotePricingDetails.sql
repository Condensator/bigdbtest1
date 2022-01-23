SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[QuotePricingDetails](
	[Id] [bigint] NOT NULL,
	[PurchasePrice_Amount] [decimal](16, 2) NULL,
	[PurchasePrice_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[DownPaymentAmount_Amount] [decimal](16, 2) NULL,
	[DownPaymentAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[AdvanceToDealer_Amount] [decimal](16, 2) NULL,
	[AdvanceToDealer_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[InterestRate] [decimal](5, 2) NULL,
	[APR] [decimal](5, 2) NULL,
	[QuoteLeaseTypeId] [bigint] NOT NULL,
	[DownPaymentPercentageId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[QuotePricingDetails]  WITH CHECK ADD  CONSTRAINT [EQuote_QuotePricingDetail] FOREIGN KEY([Id])
REFERENCES [dbo].[Quotes] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[QuotePricingDetails] CHECK CONSTRAINT [EQuote_QuotePricingDetail]
GO
ALTER TABLE [dbo].[QuotePricingDetails]  WITH CHECK ADD  CONSTRAINT [EQuotePricingDetail_DownPaymentPercentage] FOREIGN KEY([DownPaymentPercentageId])
REFERENCES [dbo].[QuoteDownPayments] ([Id])
GO
ALTER TABLE [dbo].[QuotePricingDetails] CHECK CONSTRAINT [EQuotePricingDetail_DownPaymentPercentage]
GO
ALTER TABLE [dbo].[QuotePricingDetails]  WITH CHECK ADD  CONSTRAINT [EQuotePricingDetail_QuoteLeaseType] FOREIGN KEY([QuoteLeaseTypeId])
REFERENCES [dbo].[QuoteLeaseTypes] ([Id])
GO
ALTER TABLE [dbo].[QuotePricingDetails] CHECK CONSTRAINT [EQuotePricingDetail_QuoteLeaseType]
GO
