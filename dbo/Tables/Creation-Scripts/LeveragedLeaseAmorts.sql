SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LeveragedLeaseAmorts](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IncomeDate] [date] NOT NULL,
	[ResidualIncome_Amount] [decimal](24, 2) NULL,
	[ResidualIncome_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[DepreciationExpense_Amount] [decimal](24, 2) NULL,
	[DepreciationExpense_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[InterestOnLoan_Amount] [decimal](24, 2) NULL,
	[InterestOnLoan_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[OtherExpense_Amount] [decimal](24, 2) NULL,
	[OtherExpense_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[TaxIDC_Amount] [decimal](24, 2) NULL,
	[TaxIDC_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[TaxableIncome_Amount] [decimal](24, 2) NULL,
	[TaxableIncome_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[RentalCash_Amount] [decimal](24, 2) NULL,
	[RentalCash_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[DebtService_Amount] [decimal](24, 2) NULL,
	[DebtService_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[OtherCash_Amount] [decimal](24, 2) NULL,
	[OtherCash_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[NetRentReceivable_Amount] [decimal](24, 2) NULL,
	[NetRentReceivable_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[UnearnedIncome_Amount] [decimal](24, 2) NULL,
	[UnearnedIncome_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[DeferedITCTaxUnAmort_Amount] [decimal](24, 2) NULL,
	[DeferedITCTaxUnAmort_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[DeferedIDCTaxUnAmort_Amount] [decimal](24, 2) NULL,
	[DeferedIDCTaxUnAmort_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[ResidualReceivable_Amount] [decimal](24, 2) NULL,
	[ResidualReceivable_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[DeferredTaxes_Amount] [decimal](24, 2) NULL,
	[DeferredTaxes_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[DeferredTaxesAccrued_Amount] [decimal](24, 2) NULL,
	[DeferredTaxesAccrued_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[PreTaxIncome_Amount] [decimal](24, 2) NULL,
	[PreTaxIncome_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[TaxEffectOfPreTaxIncome_Amount] [decimal](24, 2) NULL,
	[TaxEffectOfPreTaxIncome_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[IDC_Amount] [decimal](24, 2) NULL,
	[IDC_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[ITC_Amount] [decimal](24, 2) NULL,
	[ITC_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[FSCExclusion_Amount] [decimal](24, 2) NULL,
	[FSCExclusion_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[SubpartFIncome_Amount] [decimal](24, 2) NULL,
	[SubpartFIncome_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[ParentIncome_Amount] [decimal](24, 2) NULL,
	[ParentIncome_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[AMTDepreciation_Amount] [decimal](24, 2) NULL,
	[AMTDepreciation_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[DepreciationPreference_Amount] [decimal](24, 2) NULL,
	[DepreciationPreference_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[FreeCash_Amount] [decimal](24, 2) NULL,
	[FreeCash_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[NonRecourseDebtBalance_Amount] [decimal](24, 2) NULL,
	[NonRecourseDebtBalance_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[IsGLPosted] [bit] NOT NULL,
	[IsAddedAfterRestructure] [bit] NOT NULL,
	[IsAccounting] [bit] NOT NULL,
	[IsSchedule] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[LeveragedLeaseId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[LeveragedLeaseAmorts]  WITH CHECK ADD  CONSTRAINT [ELeveragedLease_LeveragedLeaseAmorts] FOREIGN KEY([LeveragedLeaseId])
REFERENCES [dbo].[LeveragedLeases] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[LeveragedLeaseAmorts] CHECK CONSTRAINT [ELeveragedLease_LeveragedLeaseAmorts]
GO
