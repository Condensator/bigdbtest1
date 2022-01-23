SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PayoffSecurityDeposits](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[TransferToIncome_Amount] [decimal](16, 2) NOT NULL,
	[TransferToIncome_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[TransferToReceipt_Amount] [decimal](16, 2) NOT NULL,
	[TransferToReceipt_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Refund] [bit] NOT NULL,
	[PayableDate] [date] NULL,
	[AppliedToPayoff_Amount] [decimal](16, 2) NOT NULL,
	[AppliedToPayoff_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Balance_Amount] [decimal](16, 2) NOT NULL,
	[Balance_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[AvailableAmount_Amount] [decimal](16, 2) NOT NULL,
	[AvailableAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[PartyId] [bigint] NULL,
	[PayableRemitToId] [bigint] NULL,
	[PayableCodeId] [bigint] NULL,
	[SecurityDepositAllocationId] [bigint] NOT NULL,
	[SecurityDepositApplicationId] [bigint] NULL,
	[PayoffId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[AppliedToReceivables_Amount] [decimal](16, 2) NOT NULL,
	[AppliedToReceivables_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[WithholdingTaxRate] [decimal](5, 2) NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[PayoffSecurityDeposits]  WITH CHECK ADD  CONSTRAINT [EPayoff_PayoffSecurityDeposits] FOREIGN KEY([PayoffId])
REFERENCES [dbo].[Payoffs] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[PayoffSecurityDeposits] CHECK CONSTRAINT [EPayoff_PayoffSecurityDeposits]
GO
ALTER TABLE [dbo].[PayoffSecurityDeposits]  WITH CHECK ADD  CONSTRAINT [EPayoffSecurityDeposit_Party] FOREIGN KEY([PartyId])
REFERENCES [dbo].[Vendors] ([Id])
GO
ALTER TABLE [dbo].[PayoffSecurityDeposits] CHECK CONSTRAINT [EPayoffSecurityDeposit_Party]
GO
ALTER TABLE [dbo].[PayoffSecurityDeposits]  WITH CHECK ADD  CONSTRAINT [EPayoffSecurityDeposit_PayableCode] FOREIGN KEY([PayableCodeId])
REFERENCES [dbo].[PayableCodes] ([Id])
GO
ALTER TABLE [dbo].[PayoffSecurityDeposits] CHECK CONSTRAINT [EPayoffSecurityDeposit_PayableCode]
GO
ALTER TABLE [dbo].[PayoffSecurityDeposits]  WITH CHECK ADD  CONSTRAINT [EPayoffSecurityDeposit_PayableRemitTo] FOREIGN KEY([PayableRemitToId])
REFERENCES [dbo].[RemitToes] ([Id])
GO
ALTER TABLE [dbo].[PayoffSecurityDeposits] CHECK CONSTRAINT [EPayoffSecurityDeposit_PayableRemitTo]
GO
ALTER TABLE [dbo].[PayoffSecurityDeposits]  WITH CHECK ADD  CONSTRAINT [EPayoffSecurityDeposit_SecurityDepositAllocation] FOREIGN KEY([SecurityDepositAllocationId])
REFERENCES [dbo].[SecurityDepositAllocations] ([Id])
GO
ALTER TABLE [dbo].[PayoffSecurityDeposits] CHECK CONSTRAINT [EPayoffSecurityDeposit_SecurityDepositAllocation]
GO
ALTER TABLE [dbo].[PayoffSecurityDeposits]  WITH CHECK ADD  CONSTRAINT [EPayoffSecurityDeposit_SecurityDepositApplication] FOREIGN KEY([SecurityDepositApplicationId])
REFERENCES [dbo].[SecurityDepositApplications] ([Id])
GO
ALTER TABLE [dbo].[PayoffSecurityDeposits] CHECK CONSTRAINT [EPayoffSecurityDeposit_SecurityDepositApplication]
GO
