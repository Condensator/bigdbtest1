CREATE TYPE [dbo].[CurrencyExchangeRateTrackerDetail] AS TABLE(
	[ExchangeRate] [decimal](20, 10) NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[EffectiveDate] [date] NOT NULL,
	[ForeignCurrencyId] [bigint] NOT NULL,
	[CurrencyExchangeRateTrackerId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
