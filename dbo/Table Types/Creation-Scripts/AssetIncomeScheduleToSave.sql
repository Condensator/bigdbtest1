CREATE TYPE [dbo].[AssetIncomeScheduleToSave] AS TABLE(
	[BeginNetBookValue_Amount] [decimal](16, 2) NOT NULL,
	[EndNetBookValue_Amount] [decimal](16, 2) NOT NULL,
	[Income_Amount] [decimal](16, 2) NOT NULL,
	[IncomeAccrued_Amount] [decimal](16, 2) NOT NULL,
	[IncomeBalance_Amount] [decimal](16, 2) NOT NULL,
	[ResidualIncome_Amount] [decimal](16, 2) NOT NULL,
	[ResidualIncomeBalance_Amount] [decimal](16, 2) NOT NULL,
	[OperatingBeginNetBookValue_Amount] [decimal](16, 2) NOT NULL,
	[OperatingEndNetBookValue_Amount] [decimal](16, 2) NOT NULL,
	[RentalIncome_Amount] [decimal](16, 2) NOT NULL,
	[DeferredRentalIncome_Amount] [decimal](16, 2) NOT NULL,
	[Depreciation_Amount] [decimal](16, 2) NOT NULL,
	[Payment_Amount] [decimal](16, 2) NOT NULL,
	[AssetId] [bigint] NOT NULL,
	[LeaseIncomeScheduleId] [bigint] NOT NULL
)
GO
