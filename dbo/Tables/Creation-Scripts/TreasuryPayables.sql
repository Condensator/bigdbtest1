SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TreasuryPayables](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[RequestedPaymentDate] [date] NULL,
	[Amount_Amount] [decimal](16, 2) NOT NULL,
	[Amount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Balance_Amount] [decimal](16, 2) NOT NULL,
	[Balance_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Status] [nvarchar](17) COLLATE Latin1_General_CI_AS NOT NULL,
	[ApprovalComment] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[Urgency] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[Memo] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[Comment] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[ReceiptType] [nvarchar](5) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[LegalEntityId] [bigint] NOT NULL,
	[CurrencyId] [bigint] NOT NULL,
	[PayeeId] [bigint] NOT NULL,
	[RemitToId] [bigint] NULL,
	[PayFromAccountId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[MailingInstruction] [nvarchar](2) COLLATE Latin1_General_CI_AS NULL,
	[ContractSequenceNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[PayableInvoiceNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[TransactionNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[TreasuryPayables]  WITH CHECK ADD  CONSTRAINT [ETreasuryPayable_Currency] FOREIGN KEY([CurrencyId])
REFERENCES [dbo].[Currencies] ([Id])
GO
ALTER TABLE [dbo].[TreasuryPayables] CHECK CONSTRAINT [ETreasuryPayable_Currency]
GO
ALTER TABLE [dbo].[TreasuryPayables]  WITH CHECK ADD  CONSTRAINT [ETreasuryPayable_LegalEntity] FOREIGN KEY([LegalEntityId])
REFERENCES [dbo].[LegalEntities] ([Id])
GO
ALTER TABLE [dbo].[TreasuryPayables] CHECK CONSTRAINT [ETreasuryPayable_LegalEntity]
GO
ALTER TABLE [dbo].[TreasuryPayables]  WITH CHECK ADD  CONSTRAINT [ETreasuryPayable_Payee] FOREIGN KEY([PayeeId])
REFERENCES [dbo].[Vendors] ([Id])
GO
ALTER TABLE [dbo].[TreasuryPayables] CHECK CONSTRAINT [ETreasuryPayable_Payee]
GO
ALTER TABLE [dbo].[TreasuryPayables]  WITH CHECK ADD  CONSTRAINT [ETreasuryPayable_PayFromAccount] FOREIGN KEY([PayFromAccountId])
REFERENCES [dbo].[BankAccounts] ([Id])
GO
ALTER TABLE [dbo].[TreasuryPayables] CHECK CONSTRAINT [ETreasuryPayable_PayFromAccount]
GO
ALTER TABLE [dbo].[TreasuryPayables]  WITH CHECK ADD  CONSTRAINT [ETreasuryPayable_RemitTo] FOREIGN KEY([RemitToId])
REFERENCES [dbo].[RemitToes] ([Id])
GO
ALTER TABLE [dbo].[TreasuryPayables] CHECK CONSTRAINT [ETreasuryPayable_RemitTo]
GO
