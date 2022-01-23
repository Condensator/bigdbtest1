SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AcceleratedBalanceDetailForLeases](
	[Id] [bigint] NOT NULL,
	[PaymentType] [nvarchar](9) COLLATE Latin1_General_CI_AS NULL,
	[PaymentAmount_Amount] [decimal](16, 2) NULL,
	[PaymentAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[NumberofLeaseRentalsPartiallyPaid_Invoiced] [bigint] NULL,
	[PartiallyPaidLeaseRentAmount_Amount] [decimal](16, 2) NULL,
	[PartiallyPaidLeaseRentAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[NumberofUnpaidLeaseRentals] [bigint] NULL,
	[TotalUnpaidRent_Amount] [decimal](16, 2) NULL,
	[TotalUnpaidRent_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[DiscountAllUnpaidRent] [bit] NOT NULL,
	[NumberofPaymentsRemaining] [bigint] NULL,
	[TotalRemainingRent_Amount] [decimal](16, 2) NULL,
	[TotalRemainingRent_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[PresentValueDiscount] [decimal](6, 3) NULL,
	[InterimRentAndInterimInterest_Amount] [decimal](16, 2) NULL,
	[InterimRentAndInterimInterest_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[StipulatedLossPercentage] [decimal](6, 3) NULL,
	[StipulatedLossInvoiceCost_Amount] [decimal](16, 2) NULL,
	[StipulatedLossInvoiceCost_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[StipulatedLoss_Amount] [decimal](16, 2) NULL,
	[StipulatedLoss_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[OptionValue_Amount] [decimal](16, 2) NULL,
	[OptionValue_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[SalesTaxStatus] [nvarchar](8) COLLATE Latin1_General_CI_AS NULL,
	[PartiallyUnpaidSalesTax_Amount] [decimal](16, 2) NULL,
	[PartiallyUnpaidSalesTax_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[SalesTaxPercent_US] [decimal](9, 6) NULL,
	[CanadianTaxPercent] [decimal](9, 6) NULL,
	[Province] [nvarchar](23) COLLATE Latin1_General_CI_AS NULL,
	[UnpaidOrOpenPropertyTax_Amount] [decimal](16, 2) NULL,
	[UnpaidOrOpenPropertyTax_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[UnpaidOrOpenSalesTaxonPPT_Amount] [decimal](16, 2) NULL,
	[UnpaidOrOpenSalesTaxonPPT_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[SalesTaxonEstimatedPropertyTax] [decimal](9, 6) NULL,
	[PastDuePayments_Amount] [decimal](16, 2) NULL,
	[PastDuePayments_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[SalesTax_Amount] [decimal](16, 2) NULL,
	[SalesTax_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[PersonalPropertyTax_Amount] [decimal](16, 2) NULL,
	[PersonalPropertyTax_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[ExpensesAndFees_Amount] [decimal](16, 2) NULL,
	[ExpensesAndFees_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[Asof] [date] NULL,
	[Location] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[AmountPastDue_Amount] [decimal](16, 2) NULL,
	[AmountPastDue_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[TotalInvoicedUnpaidRent_Amount] [decimal](16, 2) NULL,
	[TotalInvoicedUnpaidRent_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[TotalUninvoicedRent_Amount] [decimal](16, 2) NULL,
	[TotalUninvoicedRent_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[PurchaseOption_Amount] [decimal](16, 2) NULL,
	[PurchaseOption_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[StipulatedLossAmount_Amount] [decimal](16, 2) NULL,
	[StipulatedLossAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[DiscountProvidedonRentals_Amount] [decimal](16, 2) NULL,
	[DiscountProvidedonRentals_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[DiscountProvidedonResidual_Amount] [decimal](16, 2) NULL,
	[DiscountProvidedonResidual_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[TaxForUSorCAN_Amount] [decimal](16, 2) NULL,
	[TaxForUSorCAN_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[TotalPropertyTaxes_Amount] [decimal](16, 2) NULL,
	[TotalPropertyTaxes_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[SalesTaxonPPT_Amount] [decimal](16, 2) NULL,
	[SalesTaxonPPT_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[ExpenseAndFees_AmountDue_Amount] [decimal](16, 2) NULL,
	[ExpenseAndFees_AmountDue_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[ExpenseAndFees_Waivers_Amount] [decimal](16, 2) NULL,
	[ExpenseAndFees_Waivers_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[Credits_Amount] [decimal](16, 2) NULL,
	[Credits_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[TotalAcceleratedBalance_Amount] [decimal](16, 2) NULL,
	[TotalAcceleratedBalance_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RowVersion] [timestamp] NOT NULL,
	[EndOfTermPurchaseOptionId] [bigint] NULL,
	[UnpaidLeaseRentAmount_Amount] [decimal](16, 2) NULL,
	[UnpaidLeaseRentAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[AcceleratedBalanceDetailForLeases]  WITH CHECK ADD  CONSTRAINT [EAcceleratedBalanceDetail_AcceleratedBalanceDetailForLease] FOREIGN KEY([Id])
REFERENCES [dbo].[AcceleratedBalanceDetails] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[AcceleratedBalanceDetailForLeases] CHECK CONSTRAINT [EAcceleratedBalanceDetail_AcceleratedBalanceDetailForLease]
GO
ALTER TABLE [dbo].[AcceleratedBalanceDetailForLeases]  WITH CHECK ADD  CONSTRAINT [EAcceleratedBalanceDetailForLease_EndOfTermPurchaseOption] FOREIGN KEY([EndOfTermPurchaseOptionId])
REFERENCES [dbo].[DealProductTypes] ([Id])
GO
ALTER TABLE [dbo].[AcceleratedBalanceDetailForLeases] CHECK CONSTRAINT [EAcceleratedBalanceDetailForLease_EndOfTermPurchaseOption]
GO
