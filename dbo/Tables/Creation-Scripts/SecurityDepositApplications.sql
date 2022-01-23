SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SecurityDepositApplications](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[EntityType] [nvarchar](11) COLLATE Latin1_General_CI_AS NULL,
	[TransferToIncome_Amount] [decimal](16, 2) NOT NULL,
	[TransferToIncome_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[TransferToReceipt_Amount] [decimal](16, 2) NOT NULL,
	[TransferToReceipt_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[PostDate] [date] NULL,
	[IsRefund] [bit] NOT NULL,
	[PayableDate] [date] NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ReceiptId] [bigint] NULL,
	[GlJournalId] [bigint] NULL,
	[ContractId] [bigint] NULL,
	[PartyId] [bigint] NULL,
	[PayableCodeId] [bigint] NULL,
	[PayableRemitToId] [bigint] NULL,
	[SecurityDepositId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[AssumedAmount_Amount] [decimal](16, 2) NOT NULL,
	[AssumedAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[WithholdingTaxRate] [decimal](5, 2) NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[SecurityDepositApplications]  WITH CHECK ADD  CONSTRAINT [ESecurityDeposit_SecurityDepositApplications] FOREIGN KEY([SecurityDepositId])
REFERENCES [dbo].[SecurityDeposits] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[SecurityDepositApplications] CHECK CONSTRAINT [ESecurityDeposit_SecurityDepositApplications]
GO
ALTER TABLE [dbo].[SecurityDepositApplications]  WITH CHECK ADD  CONSTRAINT [ESecurityDepositApplication_Contract] FOREIGN KEY([ContractId])
REFERENCES [dbo].[Contracts] ([Id])
GO
ALTER TABLE [dbo].[SecurityDepositApplications] CHECK CONSTRAINT [ESecurityDepositApplication_Contract]
GO
ALTER TABLE [dbo].[SecurityDepositApplications]  WITH CHECK ADD  CONSTRAINT [ESecurityDepositApplication_GlJournal] FOREIGN KEY([GlJournalId])
REFERENCES [dbo].[GLJournals] ([Id])
GO
ALTER TABLE [dbo].[SecurityDepositApplications] CHECK CONSTRAINT [ESecurityDepositApplication_GlJournal]
GO
ALTER TABLE [dbo].[SecurityDepositApplications]  WITH CHECK ADD  CONSTRAINT [ESecurityDepositApplication_Party] FOREIGN KEY([PartyId])
REFERENCES [dbo].[Parties] ([Id])
GO
ALTER TABLE [dbo].[SecurityDepositApplications] CHECK CONSTRAINT [ESecurityDepositApplication_Party]
GO
ALTER TABLE [dbo].[SecurityDepositApplications]  WITH CHECK ADD  CONSTRAINT [ESecurityDepositApplication_PayableCode] FOREIGN KEY([PayableCodeId])
REFERENCES [dbo].[PayableCodes] ([Id])
GO
ALTER TABLE [dbo].[SecurityDepositApplications] CHECK CONSTRAINT [ESecurityDepositApplication_PayableCode]
GO
ALTER TABLE [dbo].[SecurityDepositApplications]  WITH CHECK ADD  CONSTRAINT [ESecurityDepositApplication_PayableRemitTo] FOREIGN KEY([PayableRemitToId])
REFERENCES [dbo].[RemitToes] ([Id])
GO
ALTER TABLE [dbo].[SecurityDepositApplications] CHECK CONSTRAINT [ESecurityDepositApplication_PayableRemitTo]
GO
ALTER TABLE [dbo].[SecurityDepositApplications]  WITH CHECK ADD  CONSTRAINT [ESecurityDepositApplication_Receipt] FOREIGN KEY([ReceiptId])
REFERENCES [dbo].[Receipts] ([Id])
GO
ALTER TABLE [dbo].[SecurityDepositApplications] CHECK CONSTRAINT [ESecurityDepositApplication_Receipt]
GO
