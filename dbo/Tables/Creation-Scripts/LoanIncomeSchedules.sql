SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LoanIncomeSchedules](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IncomeDate] [date] NOT NULL,
	[Payment_Amount] [decimal](16, 2) NOT NULL,
	[Payment_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[BeginNetBookValue_Amount] [decimal](16, 2) NOT NULL,
	[BeginNetBookValue_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[EndNetBookValue_Amount] [decimal](16, 2) NOT NULL,
	[EndNetBookValue_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[PrincipalRepayment_Amount] [decimal](16, 2) NOT NULL,
	[PrincipalRepayment_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[PrincipalAdded_Amount] [decimal](16, 2) NOT NULL,
	[PrincipalAdded_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[InterestPayment_Amount] [decimal](16, 2) NOT NULL,
	[InterestPayment_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[UnroundedInterestAccrued] [decimal](18, 8) NOT NULL,
	[InterestAccrued_Amount] [decimal](16, 2) NOT NULL,
	[InterestAccrued_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[InterestAccrualBalance_Amount] [decimal](16, 2) NOT NULL,
	[InterestAccrualBalance_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[CapitalizedInterest_Amount] [decimal](16, 2) NOT NULL,
	[CapitalizedInterest_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[CumulativeInterestBalance_Amount] [decimal](16, 2) NOT NULL,
	[CumulativeInterestBalance_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[CompoundDate] [date] NULL,
	[IsSchedule] [bit] NOT NULL,
	[IsAccounting] [bit] NOT NULL,
	[IsSyndicated] [bit] NOT NULL,
	[IsGLPosted] [bit] NOT NULL,
	[IsNonAccrual] [bit] NOT NULL,
	[IsLessorOwned] [bit] NOT NULL,
	[CumulativeInterestAppliedToPrincipal_Amount] [decimal](16, 2) NOT NULL,
	[CumulativeInterestAppliedToPrincipal_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[AdjustmentEntry] [bit] NOT NULL,
	[InterestRate] [decimal](10, 8) NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[DisbursementId] [bigint] NULL,
	[FloatRateIndexDetailId] [bigint] NULL,
	[LoanFinanceId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[TV5InterestAccrualBalance_Amount] [decimal](16, 2) NOT NULL,
	[TV5InterestAccrualBalance_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[LoanIncomeSchedules]  WITH CHECK ADD  CONSTRAINT [ELoanIncomeSchedule_Disbursement] FOREIGN KEY([DisbursementId])
REFERENCES [dbo].[PayableInvoiceOtherCosts] ([Id])
GO
ALTER TABLE [dbo].[LoanIncomeSchedules] CHECK CONSTRAINT [ELoanIncomeSchedule_Disbursement]
GO
ALTER TABLE [dbo].[LoanIncomeSchedules]  WITH CHECK ADD  CONSTRAINT [ELoanIncomeSchedule_FloatRateIndexDetail] FOREIGN KEY([FloatRateIndexDetailId])
REFERENCES [dbo].[FloatRateIndexDetails] ([Id])
GO
ALTER TABLE [dbo].[LoanIncomeSchedules] CHECK CONSTRAINT [ELoanIncomeSchedule_FloatRateIndexDetail]
GO
ALTER TABLE [dbo].[LoanIncomeSchedules]  WITH CHECK ADD  CONSTRAINT [ELoanIncomeSchedule_LoanFinance] FOREIGN KEY([LoanFinanceId])
REFERENCES [dbo].[LoanFinances] ([Id])
GO
ALTER TABLE [dbo].[LoanIncomeSchedules] CHECK CONSTRAINT [ELoanIncomeSchedule_LoanFinance]
GO
