SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ContractMeasures](
	[Id] [bigint] NOT NULL,
	[Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[EarnedSellingProfitIncome] [decimal](16, 2) NULL,
	[EarnedIncome] [decimal](16, 2) NULL,
	[EarnedResidualIncome] [decimal](16, 2) NULL,
	[FinancingEarnedResidualIncome] [decimal](16, 2) NULL,
	[GLPostedInterimInterestIncome] [decimal](16, 2) NULL,
	[GLPostedInterimRentIncome] [decimal](16, 2) NULL,
	[TotalGLPostedFloatRateIncome] [decimal](16, 2) NULL,
	[ChargeOffExpenseNLC] [decimal](16, 2) NULL,
	[ChargeOffRecoveryLeaseComponent] [decimal](16, 2) NULL,
	[ChargeOffRecoveryNonLeaseComponent] [decimal](16, 2) NULL,
	[ChargeOffGainOnRecoveryLeaseComponent] [decimal](16, 2) NULL,
	[ChargeOffGainOnRecoveryNonLeaseComponent] [decimal](16, 2) NULL,
	[ChargeOffExpenseLeaseComponent] [decimal](16, 2) NULL,
	[RecoveryIncome] [decimal](16, 2) NULL,
	[RentalIncome] [decimal](16, 2) NULL,
	[DepreciationAmount] [decimal](16, 2) NULL,
	[NBVImpairment] [decimal](16, 2) NULL,
	[SupplementalIncome] [decimal](16, 2) NULL,
	[OTPIncome] [decimal](16, 2) NULL,
	[BlendedIncome] [decimal](16, 2) NULL,
	[SyndicationServiceFee] [decimal](16, 2) NULL,
	[OTPDepreciation] [decimal](16, 2) NULL,
	[ImpairmentAdjustmentPayoff] [decimal](16, 2) NULL,
	[BlendedExpense] [decimal](16, 2) NULL,
	[SyndicationServiceFeeAbsorb] [decimal](16, 2) NULL,
	[ResidualRecapture] [decimal](16, 2) NULL,
	[FinancingLossOnUnguaranteedResidual] [decimal](16, 2) NULL,
	[LossOnUnguaranteedResidual] [decimal](16, 2) NULL,
	[SaleProceeds] [decimal](16, 2) NULL,
	[SalesTypeLeaseGrossProfit] [decimal](16, 2) NULL,
	[Revenue] [decimal](16, 2) NULL,
	[FinancingRevenue] [decimal](16, 2) NULL,
	[FinanceEarnedIncome] [decimal](16, 2) NULL,
	[ScrapeReceivableIncome] [decimal](16, 2) NULL,
	[AdditionalFeeIncome] [decimal](16, 2) NULL,
	[TransferToIncome] [decimal](16, 2) NULL,
	[CostOfGoodsSold] [decimal](16, 2) NULL,
	[FinancingCostOfGoodsSold] [decimal](16, 2) NULL,
	[ScrapePayableExpenseRecognition] [decimal](16, 2) NULL,
	[NetChargeOff] [decimal](16, 2) NULL,
	[ValuationExpense] [decimal](16, 2) NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ContractMeasures]  WITH CHECK ADD  CONSTRAINT [EContract_ContractMeasures] FOREIGN KEY([Id])
REFERENCES [dbo].[Contracts] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[ContractMeasures] CHECK CONSTRAINT [EContract_ContractMeasures]
GO
