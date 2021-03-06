CREATE TYPE [dbo].[AssetIncomeAmortTVP] AS TABLE(
	[LeaseIncomeKey] [bigint] NULL,
	[AssetId] [bigint] NULL,
	[Currency] [nvarchar](6) COLLATE Latin1_General_CI_AS NULL,
	[BeginNBV] [decimal](16, 2) NULL,
	[EndNBV] [decimal](16, 2) NULL,
	[Payment] [decimal](16, 2) NULL,
	[Income] [decimal](16, 2) NULL,
	[IncomeAccrued] [decimal](16, 2) NULL,
	[IncomeBalance] [decimal](16, 2) NULL,
	[ResidualIncome] [decimal](16, 2) NULL,
	[ResidualIncomeBalance] [decimal](16, 2) NULL,
	[DSPIncome] [decimal](16, 2) NULL,
	[DSPIncomeBalance] [decimal](16, 2) NULL,
	[RentalIncome] [decimal](16, 2) NULL,
	[DeferredRentalIncome] [decimal](16, 2) NULL,
	[OperatingBeginNBV] [decimal](16, 2) NULL,
	[OperatingEndNBV] [decimal](16, 2) NULL,
	[Depreciation] [decimal](16, 2) NULL,
	[IsActive] [bit] NULL,
	[FinanceBeginNBV] [decimal](16, 2) NULL,
	[FinanceEndNBV] [decimal](16, 2) NULL,
	[FinancePayment] [decimal](16, 2) NULL,
	[FinanceIncome] [decimal](16, 2) NULL,
	[FinanceIncomeAccrued] [decimal](16, 2) NULL,
	[FinanceIncomeBalance] [decimal](16, 2) NULL,
	[FinanceResidualIncome] [decimal](16, 2) NULL,
	[FinanceResidualIncomeBalance] [decimal](16, 2) NULL,
	[FinanceRentalIncome] [decimal](16, 2) NULL,
	[FinanceDeferredRentalIncome] [decimal](16, 2) NULL,
	[LeaseBeginNBV] [decimal](16, 2) NULL,
	[LeaseEndNBV] [decimal](16, 2) NULL,
	[LeasePayment] [decimal](16, 2) NULL,
	[LeaseIncome] [decimal](16, 2) NULL,
	[LeaseIncomeAccrued] [decimal](16, 2) NULL,
	[LeaseIncomeBalance] [decimal](16, 2) NULL,
	[LeaseResidualIncome] [decimal](16, 2) NULL,
	[LeaseResidualIncomeBalance] [decimal](16, 2) NULL,
	[LeaseRentalIncome] [decimal](16, 2) NULL,
	[LeaseDeferredRentalIncome] [decimal](16, 2) NULL
)
GO
