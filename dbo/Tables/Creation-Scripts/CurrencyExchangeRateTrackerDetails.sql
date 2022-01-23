SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CurrencyExchangeRateTrackerDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[ExchangeRate] [decimal](20, 10) NOT NULL,
	[EffectiveDate] [date] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ForeignCurrencyId] [bigint] NOT NULL,
	[CurrencyExchangeRateTrackerId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CurrencyExchangeRateTrackerDetails]  WITH CHECK ADD  CONSTRAINT [ECurrencyExchangeRateTracker_CurrencyExchangeRateTrackerDetails] FOREIGN KEY([CurrencyExchangeRateTrackerId])
REFERENCES [dbo].[CurrencyExchangeRateTrackers] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CurrencyExchangeRateTrackerDetails] CHECK CONSTRAINT [ECurrencyExchangeRateTracker_CurrencyExchangeRateTrackerDetails]
GO
ALTER TABLE [dbo].[CurrencyExchangeRateTrackerDetails]  WITH CHECK ADD  CONSTRAINT [ECurrencyExchangeRateTrackerDetail_ForeignCurrency] FOREIGN KEY([ForeignCurrencyId])
REFERENCES [dbo].[Currencies] ([Id])
GO
ALTER TABLE [dbo].[CurrencyExchangeRateTrackerDetails] CHECK CONSTRAINT [ECurrencyExchangeRateTrackerDetail_ForeignCurrency]
GO
