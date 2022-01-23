CREATE TYPE [dbo].[TaxDepAmortForeCast] AS TABLE(
	[BonusDepreciationAmount_Amount] [decimal](18, 2) NULL,
	[BonusDepreciationAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[DepreciationEndDate] [datetime] NULL,
	[FirstYearTaxDepreciationForecast_Amount] [decimal](18, 2) NULL,
	[FirstYearTaxDepreciationForecast_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[LastYearTaxDepreciationForecast_Amount] [decimal](18, 2) NULL,
	[LastYearTaxDepreciationForecast_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[TaxDepreciationTemplateDetailId] [bigint] NULL,
	[CurrencyId] [bigint] NULL
)
GO
