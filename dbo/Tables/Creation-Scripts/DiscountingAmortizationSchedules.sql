SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DiscountingAmortizationSchedules](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[ExpenseDate] [date] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[PaymentAmount_Amount] [decimal](16, 2) NOT NULL,
	[PaymentAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[BeginNetBookValue_Amount] [decimal](16, 2) NOT NULL,
	[BeginNetBookValue_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[EndNetBookValue_Amount] [decimal](16, 2) NOT NULL,
	[EndNetBookValue_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[PrincipalRepaid_Amount] [decimal](16, 2) NOT NULL,
	[PrincipalRepaid_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[PrincipalAdded_Amount] [decimal](16, 2) NOT NULL,
	[PrincipalAdded_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[InterestPayment_Amount] [decimal](16, 2) NOT NULL,
	[InterestPayment_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[InterestAccrued_Amount] [decimal](16, 2) NOT NULL,
	[InterestAccrued_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[InterestAccrualBalance_Amount] [decimal](16, 2) NOT NULL,
	[InterestAccrualBalance_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[InterestRate] [decimal](14, 9) NOT NULL,
	[IsSchedule] [bit] NOT NULL,
	[IsAccounting] [bit] NOT NULL,
	[IsGLPosted] [bit] NOT NULL,
	[IsNonAccrual] [bit] NOT NULL,
	[DiscountingFinanceId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[CapitalizedInterest_Amount] [decimal](16, 2) NOT NULL,
	[CapitalizedInterest_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[ModificationType] [nvarchar](11) COLLATE Latin1_General_CI_AS NOT NULL,
	[ModificationID] [bigint] NOT NULL,
	[AdjustmentEntry] [bit] NOT NULL,
	[PrincipalGainLoss_Amount] [decimal](16, 2) NOT NULL,
	[PrincipalGainLoss_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[InterestGainLoss_Amount] [decimal](16, 2) NOT NULL,
	[InterestGainLoss_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[DiscountingAmortizationSchedules]  WITH CHECK ADD  CONSTRAINT [EDiscountingAmortizationSchedule_DiscountingFinance] FOREIGN KEY([DiscountingFinanceId])
REFERENCES [dbo].[DiscountingFinances] ([Id])
GO
ALTER TABLE [dbo].[DiscountingAmortizationSchedules] CHECK CONSTRAINT [EDiscountingAmortizationSchedule_DiscountingFinance]
GO
