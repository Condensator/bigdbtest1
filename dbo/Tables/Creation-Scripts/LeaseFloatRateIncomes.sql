SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LeaseFloatRateIncomes](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IncomeDate] [date] NOT NULL,
	[CustomerIncomeAmount_Amount] [decimal](16, 2) NOT NULL,
	[CustomerIncomeAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[CustomerIncomeAccruedAmount_Amount] [decimal](16, 2) NOT NULL,
	[CustomerIncomeAccruedAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[CustomerReceivableAmount_Amount] [decimal](16, 2) NOT NULL,
	[CustomerReceivableAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsGLPosted] [bit] NOT NULL,
	[IsAccounting] [bit] NOT NULL,
	[IsScheduled] [bit] NOT NULL,
	[IsNonAccrual] [bit] NOT NULL,
	[ModificationType] [nvarchar](31) COLLATE Latin1_General_CI_AS NOT NULL,
	[ModificationId] [bigint] NOT NULL,
	[AdjustmentEntry] [bit] NOT NULL,
	[IsLessorOwned] [bit] NOT NULL,
	[InterestRate] [decimal](10, 8) NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[FloatRateIndexDetailId] [bigint] NULL,
	[LeaseFinanceId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[LeaseFloatRateIncomes]  WITH CHECK ADD  CONSTRAINT [ELeaseFloatRateIncome_FloatRateIndexDetail] FOREIGN KEY([FloatRateIndexDetailId])
REFERENCES [dbo].[FloatRateIndexDetails] ([Id])
GO
ALTER TABLE [dbo].[LeaseFloatRateIncomes] CHECK CONSTRAINT [ELeaseFloatRateIncome_FloatRateIndexDetail]
GO
ALTER TABLE [dbo].[LeaseFloatRateIncomes]  WITH CHECK ADD  CONSTRAINT [ELeaseFloatRateIncome_LeaseFinance] FOREIGN KEY([LeaseFinanceId])
REFERENCES [dbo].[LeaseFinances] ([Id])
GO
ALTER TABLE [dbo].[LeaseFloatRateIncomes] CHECK CONSTRAINT [ELeaseFloatRateIncome_LeaseFinance]
GO
