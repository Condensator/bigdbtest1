SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LoanFinanceAdditionalCharges](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[SundryId] [bigint] NULL,
	[RecurringSundryId] [bigint] NULL,
	[LoanFinanceId] [bigint] NOT NULL,
	[AdditionalChargeId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[LoanFinanceAdditionalCharges]  WITH CHECK ADD  CONSTRAINT [ELoanFinance_LoanFinanceAdditionalCharges] FOREIGN KEY([LoanFinanceId])
REFERENCES [dbo].[LoanFinances] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[LoanFinanceAdditionalCharges] CHECK CONSTRAINT [ELoanFinance_LoanFinanceAdditionalCharges]
GO
ALTER TABLE [dbo].[LoanFinanceAdditionalCharges]  WITH CHECK ADD  CONSTRAINT [ELoanFinanceAdditionalCharge_AdditionalCharge] FOREIGN KEY([AdditionalChargeId])
REFERENCES [dbo].[AdditionalCharges] ([Id])
GO
ALTER TABLE [dbo].[LoanFinanceAdditionalCharges] CHECK CONSTRAINT [ELoanFinanceAdditionalCharge_AdditionalCharge]
GO
ALTER TABLE [dbo].[LoanFinanceAdditionalCharges]  WITH CHECK ADD  CONSTRAINT [ELoanFinanceAdditionalCharge_RecurringSundry] FOREIGN KEY([RecurringSundryId])
REFERENCES [dbo].[SundryRecurrings] ([Id])
GO
ALTER TABLE [dbo].[LoanFinanceAdditionalCharges] CHECK CONSTRAINT [ELoanFinanceAdditionalCharge_RecurringSundry]
GO
ALTER TABLE [dbo].[LoanFinanceAdditionalCharges]  WITH CHECK ADD  CONSTRAINT [ELoanFinanceAdditionalCharge_Sundry] FOREIGN KEY([SundryId])
REFERENCES [dbo].[Sundries] ([Id])
GO
ALTER TABLE [dbo].[LoanFinanceAdditionalCharges] CHECK CONSTRAINT [ELoanFinanceAdditionalCharge_Sundry]
GO
