CREATE TYPE [dbo].[TaxDepAmortDetail] AS TABLE(
	[DepreciationDate] [datetime] NULL,
	[FiscalYear] [bigint] NULL,
	[BeginNetBookValue_Amount] [decimal](18, 2) NULL,
	[BeginNetBookValue_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[DepreciationAmount_Amount] [decimal](18, 2) NULL,
	[DepreciationAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[EndNetBookValue_Amount] [decimal](18, 2) NULL,
	[EndNetBookValue_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[TaxDepreciationConventionId] [bigint] NULL,
	[TaxDepreciationTemplateDetailId] [bigint] NULL,
	[CurrencyId] [bigint] NULL,
	[IsSchedule] [bit] NULL,
	[IsAccounting] [bit] NULL
)
GO
