SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LoanPaydownSecurityDeposits](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[AmountAppliedToPayDown_Amount] [decimal](16, 2) NOT NULL,
	[AmountAppliedToPayDown_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[TransferToIncome_Amount] [decimal](16, 2) NOT NULL,
	[TransferToIncome_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[TransferToReceipt_Amount] [decimal](16, 2) NOT NULL,
	[TransferToReceipt_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[IsRefund] [bit] NOT NULL,
	[PayableDate] [date] NULL,
	[AvailableAmount_Amount] [decimal](16, 2) NOT NULL,
	[AvailableAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[SecurityDepositId] [bigint] NOT NULL,
	[PartyId] [bigint] NULL,
	[PayableCodeId] [bigint] NULL,
	[PayableRemitToId] [bigint] NULL,
	[SecurityDepositAllocationId] [bigint] NOT NULL,
	[SecurityDepositApplicationId] [bigint] NULL,
	[LoanPaydownId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[WithholdingTaxRate] [decimal](5, 2) NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[LoanPaydownSecurityDeposits]  WITH CHECK ADD  CONSTRAINT [ELoanPaydown_LoanPaydownSecurityDeposits] FOREIGN KEY([LoanPaydownId])
REFERENCES [dbo].[LoanPaydowns] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[LoanPaydownSecurityDeposits] CHECK CONSTRAINT [ELoanPaydown_LoanPaydownSecurityDeposits]
GO
ALTER TABLE [dbo].[LoanPaydownSecurityDeposits]  WITH CHECK ADD  CONSTRAINT [ELoanPaydownSecurityDeposit_Party] FOREIGN KEY([PartyId])
REFERENCES [dbo].[Parties] ([Id])
GO
ALTER TABLE [dbo].[LoanPaydownSecurityDeposits] CHECK CONSTRAINT [ELoanPaydownSecurityDeposit_Party]
GO
ALTER TABLE [dbo].[LoanPaydownSecurityDeposits]  WITH CHECK ADD  CONSTRAINT [ELoanPaydownSecurityDeposit_PayableCode] FOREIGN KEY([PayableCodeId])
REFERENCES [dbo].[PayableCodes] ([Id])
GO
ALTER TABLE [dbo].[LoanPaydownSecurityDeposits] CHECK CONSTRAINT [ELoanPaydownSecurityDeposit_PayableCode]
GO
ALTER TABLE [dbo].[LoanPaydownSecurityDeposits]  WITH CHECK ADD  CONSTRAINT [ELoanPaydownSecurityDeposit_PayableRemitTo] FOREIGN KEY([PayableRemitToId])
REFERENCES [dbo].[RemitToes] ([Id])
GO
ALTER TABLE [dbo].[LoanPaydownSecurityDeposits] CHECK CONSTRAINT [ELoanPaydownSecurityDeposit_PayableRemitTo]
GO
ALTER TABLE [dbo].[LoanPaydownSecurityDeposits]  WITH CHECK ADD  CONSTRAINT [ELoanPaydownSecurityDeposit_SecurityDeposit] FOREIGN KEY([SecurityDepositId])
REFERENCES [dbo].[SecurityDeposits] ([Id])
GO
ALTER TABLE [dbo].[LoanPaydownSecurityDeposits] CHECK CONSTRAINT [ELoanPaydownSecurityDeposit_SecurityDeposit]
GO
ALTER TABLE [dbo].[LoanPaydownSecurityDeposits]  WITH CHECK ADD  CONSTRAINT [ELoanPaydownSecurityDeposit_SecurityDepositAllocation] FOREIGN KEY([SecurityDepositAllocationId])
REFERENCES [dbo].[SecurityDepositAllocations] ([Id])
GO
ALTER TABLE [dbo].[LoanPaydownSecurityDeposits] CHECK CONSTRAINT [ELoanPaydownSecurityDeposit_SecurityDepositAllocation]
GO
ALTER TABLE [dbo].[LoanPaydownSecurityDeposits]  WITH CHECK ADD  CONSTRAINT [ELoanPaydownSecurityDeposit_SecurityDepositApplication] FOREIGN KEY([SecurityDepositApplicationId])
REFERENCES [dbo].[SecurityDepositApplications] ([Id])
GO
ALTER TABLE [dbo].[LoanPaydownSecurityDeposits] CHECK CONSTRAINT [ELoanPaydownSecurityDeposit_SecurityDepositApplication]
GO
