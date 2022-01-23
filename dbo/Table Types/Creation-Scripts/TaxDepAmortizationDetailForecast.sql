CREATE TYPE [dbo].[TaxDepAmortizationDetailForecast] AS TABLE(
	[BonusDepreciationAmount_Amount] [decimal](16, 2) NOT NULL,
	[BonusDepreciationAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[DepreciationEndDate] [date] NULL,
	[FirstYearTaxDepreciationForecast_Amount] [decimal](16, 2) NOT NULL,
	[FirstYearTaxDepreciationForecast_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[LastYearTaxDepreciationForecast_Amount] [decimal](16, 2) NOT NULL,
	[LastYearTaxDepreciationForecast_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[TaxDepAmortizationId] [bigint] NOT NULL,
	[TaxDepreciationTemplateDetailId] [bigint] NOT NULL,
	[CurrencyId] [bigint] NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
