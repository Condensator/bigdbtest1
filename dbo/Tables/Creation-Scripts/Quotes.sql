SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Quotes](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Number] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[EstimatedFinancialAmount_Amount] [decimal](16, 2) NULL,
	[EstimatedFinancialAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[ResidualPercentage] [decimal](5, 2) NULL,
	[ResidualAmount_Amount] [decimal](16, 2) NULL,
	[ResidualAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[QuotePaymentAmount_Amount] [decimal](16, 2) NULL,
	[QuotePaymentAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[EstimatedBalloonAmount_Amount] [decimal](16, 2) NULL,
	[EstimatedBalloonAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[IsAdvance] [bit] NOT NULL,
	[QuoteExpirationDate] [date] NULL,
	[IsQuoteRequested] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[CurrencyId] [bigint] NOT NULL,
	[RequestedPromotionId] [bigint] NULL,
	[QuoteRequestId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[CalculatedPaymentAmount_Amount] [decimal](16, 2) NULL,
	[CalculatedPaymentAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[PortfolioId] [bigint] NOT NULL,
	[CanUsePricingEngine] [bit] NOT NULL,
	[StepPercentage] [decimal](10, 6) NULL,
	[StepPeriod] [int] NULL,
	[StubAdjustment] [nvarchar](15) COLLATE Latin1_General_CI_AS NULL,
	[StepPaymentStartDate] [date] NULL,
	[IsStepPayment] [bit] NOT NULL,
	[DayCountConvention] [nvarchar](14) COLLATE Latin1_General_CI_AS NULL,
	[ProgramRateCardRate] [decimal](10, 6) NULL,
	[ProgramRateCardYield] [decimal](10, 6) NULL,
	[ProgramAssetTypeId] [bigint] NOT NULL,
	[ProgramAssetTypeFrequencyId] [bigint] NOT NULL,
	[ProgramAssetTypeTermId] [bigint] NOT NULL,
	[ProgramAssetTypeEOTOptionId] [bigint] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[Quotes]  WITH CHECK ADD  CONSTRAINT [EQuote_Currency] FOREIGN KEY([CurrencyId])
REFERENCES [dbo].[Currencies] ([Id])
GO
ALTER TABLE [dbo].[Quotes] CHECK CONSTRAINT [EQuote_Currency]
GO
ALTER TABLE [dbo].[Quotes]  WITH CHECK ADD  CONSTRAINT [EQuote_Portfolio] FOREIGN KEY([PortfolioId])
REFERENCES [dbo].[Portfolios] ([Id])
GO
ALTER TABLE [dbo].[Quotes] CHECK CONSTRAINT [EQuote_Portfolio]
GO
ALTER TABLE [dbo].[Quotes]  WITH CHECK ADD  CONSTRAINT [EQuote_ProgramAssetType] FOREIGN KEY([ProgramAssetTypeId])
REFERENCES [dbo].[ProgramAssetTypes] ([Id])
GO
ALTER TABLE [dbo].[Quotes] CHECK CONSTRAINT [EQuote_ProgramAssetType]
GO
ALTER TABLE [dbo].[Quotes]  WITH CHECK ADD  CONSTRAINT [EQuote_ProgramAssetTypeEOTOption] FOREIGN KEY([ProgramAssetTypeEOTOptionId])
REFERENCES [dbo].[ProgramAssetTypeEOTOptions] ([Id])
GO
ALTER TABLE [dbo].[Quotes] CHECK CONSTRAINT [EQuote_ProgramAssetTypeEOTOption]
GO
ALTER TABLE [dbo].[Quotes]  WITH CHECK ADD  CONSTRAINT [EQuote_ProgramAssetTypeFrequency] FOREIGN KEY([ProgramAssetTypeFrequencyId])
REFERENCES [dbo].[ProgramAssetTypeFrequencies] ([Id])
GO
ALTER TABLE [dbo].[Quotes] CHECK CONSTRAINT [EQuote_ProgramAssetTypeFrequency]
GO
ALTER TABLE [dbo].[Quotes]  WITH CHECK ADD  CONSTRAINT [EQuote_ProgramAssetTypeTerm] FOREIGN KEY([ProgramAssetTypeTermId])
REFERENCES [dbo].[ProgramAssetTypeTerms] ([Id])
GO
ALTER TABLE [dbo].[Quotes] CHECK CONSTRAINT [EQuote_ProgramAssetTypeTerm]
GO
ALTER TABLE [dbo].[Quotes]  WITH CHECK ADD  CONSTRAINT [EQuote_RequestedPromotion] FOREIGN KEY([RequestedPromotionId])
REFERENCES [dbo].[ProgramPromotions] ([Id])
GO
ALTER TABLE [dbo].[Quotes] CHECK CONSTRAINT [EQuote_RequestedPromotion]
GO
ALTER TABLE [dbo].[Quotes]  WITH CHECK ADD  CONSTRAINT [EQuoteRequest_Quotes] FOREIGN KEY([QuoteRequestId])
REFERENCES [dbo].[QuoteRequests] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Quotes] CHECK CONSTRAINT [EQuoteRequest_Quotes]
GO
