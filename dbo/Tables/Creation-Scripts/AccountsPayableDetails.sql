SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AccountsPayableDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Amount_Amount] [decimal](16, 2) NOT NULL,
	[Amount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[RequestedPaymentDate] [date] NOT NULL,
	[ReceiptType] [nvarchar](5) COLLATE Latin1_General_CI_AS NOT NULL,
	[Urgency] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[Memo] [nvarchar](1000) COLLATE Latin1_General_CI_AS NULL,
	[ApprovalComment] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[TreasuryPayableId] [bigint] NOT NULL,
	[RemitToId] [bigint] NOT NULL,
	[PayFromAccountId] [bigint] NOT NULL,
	[AccountsPayableId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[MailingInstruction] [nvarchar](2) COLLATE Latin1_General_CI_AS NULL,
	[WithholdingTaxAmount_Amount] [decimal](16, 2) NOT NULL,
	[WithholdingTaxAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[AccountsPayableDetails]  WITH CHECK ADD  CONSTRAINT [EAccountsPayable_AccountsPayableDetails] FOREIGN KEY([AccountsPayableId])
REFERENCES [dbo].[AccountsPayables] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[AccountsPayableDetails] CHECK CONSTRAINT [EAccountsPayable_AccountsPayableDetails]
GO
ALTER TABLE [dbo].[AccountsPayableDetails]  WITH CHECK ADD  CONSTRAINT [EAccountsPayableDetail_PayFromAccount] FOREIGN KEY([PayFromAccountId])
REFERENCES [dbo].[BankAccounts] ([Id])
GO
ALTER TABLE [dbo].[AccountsPayableDetails] CHECK CONSTRAINT [EAccountsPayableDetail_PayFromAccount]
GO
ALTER TABLE [dbo].[AccountsPayableDetails]  WITH CHECK ADD  CONSTRAINT [EAccountsPayableDetail_RemitTo] FOREIGN KEY([RemitToId])
REFERENCES [dbo].[RemitToes] ([Id])
GO
ALTER TABLE [dbo].[AccountsPayableDetails] CHECK CONSTRAINT [EAccountsPayableDetail_RemitTo]
GO
ALTER TABLE [dbo].[AccountsPayableDetails]  WITH CHECK ADD  CONSTRAINT [EAccountsPayableDetail_TreasuryPayable] FOREIGN KEY([TreasuryPayableId])
REFERENCES [dbo].[TreasuryPayables] ([Id])
GO
ALTER TABLE [dbo].[AccountsPayableDetails] CHECK CONSTRAINT [EAccountsPayableDetail_TreasuryPayable]
GO
