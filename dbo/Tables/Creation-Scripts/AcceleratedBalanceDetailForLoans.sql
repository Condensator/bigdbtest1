SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AcceleratedBalanceDetailForLoans](
	[Id] [bigint] NOT NULL,
	[DayCountConvention] [nvarchar](14) COLLATE Latin1_General_CI_AS NULL,
	[PrincipalAmount_Amount] [decimal](16, 2) NULL,
	[PrincipalAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[AccruedInterestPriortoDefault_Amount] [decimal](16, 2) NULL,
	[AccruedInterestPriortoDefault_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[InterestRate] [decimal](6, 3) NULL,
	[DateInterestAccruedFrom] [date] NULL,
	[PrincipalBalance_Amount] [decimal](16, 2) NULL,
	[PrincipalBalance_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[AccruedInterest_Amount] [decimal](16, 2) NULL,
	[AccruedInterest_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[ExpensesAndFees_Amount] [decimal](16, 2) NULL,
	[ExpensesAndFees_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
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
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[AcceleratedBalanceDetailForLoans]  WITH CHECK ADD  CONSTRAINT [EAcceleratedBalanceDetail_AcceleratedBalanceDetailForLoan] FOREIGN KEY([Id])
REFERENCES [dbo].[AcceleratedBalanceDetails] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[AcceleratedBalanceDetailForLoans] CHECK CONSTRAINT [EAcceleratedBalanceDetail_AcceleratedBalanceDetailForLoan]
GO
