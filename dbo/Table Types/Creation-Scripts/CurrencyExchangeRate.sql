CREATE TYPE [dbo].[CurrencyExchangeRate] AS TABLE(
	[ExchangeRate] [decimal](20, 10) NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[EffectiveDate] [date] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[ForeignCurrencyId] [bigint] NOT NULL,
	[CurrencyId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
