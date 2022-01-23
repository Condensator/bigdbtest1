SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LoanPaymentScheduleHistories](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[EndDate] [date] NULL,
	[OriginalPaymentAmount_Amount] [decimal](16, 2) NOT NULL,
	[OriginalPaymentAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[OriginalPaymentStructure] [nvarchar](14) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[LoanFinanceId] [bigint] NOT NULL,
	[LoanPaymentScheduleId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[LoanPaymentScheduleHistories]  WITH CHECK ADD  CONSTRAINT [ELoanFinance_LoanPaymentScheduleHistories] FOREIGN KEY([LoanFinanceId])
REFERENCES [dbo].[LoanFinances] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[LoanPaymentScheduleHistories] CHECK CONSTRAINT [ELoanFinance_LoanPaymentScheduleHistories]
GO
ALTER TABLE [dbo].[LoanPaymentScheduleHistories]  WITH CHECK ADD  CONSTRAINT [ELoanPaymentScheduleHistory_LoanPaymentSchedule] FOREIGN KEY([LoanPaymentScheduleId])
REFERENCES [dbo].[LoanPaymentSchedules] ([Id])
GO
ALTER TABLE [dbo].[LoanPaymentScheduleHistories] CHECK CONSTRAINT [ELoanPaymentScheduleHistory_LoanPaymentSchedule]
GO
