SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PreQuoteSecurityDeposits](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[EntityType] [nvarchar](2) COLLATE Latin1_General_CI_AS NOT NULL,
	[AllocationType] [nvarchar](11) COLLATE Latin1_General_CI_AS NOT NULL,
	[TransferToReceipt_Amount] [decimal](16, 2) NOT NULL,
	[TransferToReceipt_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Refund] [bit] NOT NULL,
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
	[ContractId] [bigint] NULL,
	[PayableRemitToId] [bigint] NULL,
	[PayableCodeId] [bigint] NULL,
	[SecurityDepositAllocationId] [bigint] NOT NULL,
	[SecurityDepositApplicationId] [bigint] NULL,
	[PreQuoteId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[PayableDate] [date] NULL,
	[WithholdingTaxRate] [decimal](5, 2) NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[PreQuoteSecurityDeposits]  WITH CHECK ADD  CONSTRAINT [EPreQuote_PreQuoteSecurityDeposits] FOREIGN KEY([PreQuoteId])
REFERENCES [dbo].[PreQuotes] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[PreQuoteSecurityDeposits] CHECK CONSTRAINT [EPreQuote_PreQuoteSecurityDeposits]
GO
ALTER TABLE [dbo].[PreQuoteSecurityDeposits]  WITH CHECK ADD  CONSTRAINT [EPreQuoteSecurityDeposit_Contract] FOREIGN KEY([ContractId])
REFERENCES [dbo].[Contracts] ([Id])
GO
ALTER TABLE [dbo].[PreQuoteSecurityDeposits] CHECK CONSTRAINT [EPreQuoteSecurityDeposit_Contract]
GO
ALTER TABLE [dbo].[PreQuoteSecurityDeposits]  WITH CHECK ADD  CONSTRAINT [EPreQuoteSecurityDeposit_Party] FOREIGN KEY([PartyId])
REFERENCES [dbo].[Parties] ([Id])
GO
ALTER TABLE [dbo].[PreQuoteSecurityDeposits] CHECK CONSTRAINT [EPreQuoteSecurityDeposit_Party]
GO
ALTER TABLE [dbo].[PreQuoteSecurityDeposits]  WITH CHECK ADD  CONSTRAINT [EPreQuoteSecurityDeposit_PayableCode] FOREIGN KEY([PayableCodeId])
REFERENCES [dbo].[PayableCodes] ([Id])
GO
ALTER TABLE [dbo].[PreQuoteSecurityDeposits] CHECK CONSTRAINT [EPreQuoteSecurityDeposit_PayableCode]
GO
ALTER TABLE [dbo].[PreQuoteSecurityDeposits]  WITH CHECK ADD  CONSTRAINT [EPreQuoteSecurityDeposit_PayableRemitTo] FOREIGN KEY([PayableRemitToId])
REFERENCES [dbo].[RemitToes] ([Id])
GO
ALTER TABLE [dbo].[PreQuoteSecurityDeposits] CHECK CONSTRAINT [EPreQuoteSecurityDeposit_PayableRemitTo]
GO
ALTER TABLE [dbo].[PreQuoteSecurityDeposits]  WITH CHECK ADD  CONSTRAINT [EPreQuoteSecurityDeposit_SecurityDepositAllocation] FOREIGN KEY([SecurityDepositAllocationId])
REFERENCES [dbo].[SecurityDepositAllocations] ([Id])
GO
ALTER TABLE [dbo].[PreQuoteSecurityDeposits] CHECK CONSTRAINT [EPreQuoteSecurityDeposit_SecurityDepositAllocation]
GO
ALTER TABLE [dbo].[PreQuoteSecurityDeposits]  WITH CHECK ADD  CONSTRAINT [EPreQuoteSecurityDeposit_SecurityDepositApplication] FOREIGN KEY([SecurityDepositApplicationId])
REFERENCES [dbo].[SecurityDepositApplications] ([Id])
GO
ALTER TABLE [dbo].[PreQuoteSecurityDeposits] CHECK CONSTRAINT [EPreQuoteSecurityDeposit_SecurityDepositApplication]
GO
