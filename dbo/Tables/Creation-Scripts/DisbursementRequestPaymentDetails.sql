SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DisbursementRequestPaymentDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[RequestedPaymentDate] [date] NULL,
	[Urgency] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[Comment] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[Memo] [nvarchar](1000) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[RemittanceType] [nvarchar](5) COLLATE Latin1_General_CI_AS NULL,
	[TotalAmountToPay_Amount] [decimal](16, 2) NULL,
	[TotalAmountToPay_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[PayeeId] [bigint] NOT NULL,
	[RemitToId] [bigint] NULL,
	[ContactId] [bigint] NULL,
	[PayFromAccountId] [bigint] NULL,
	[DisbursementRequestId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[MailingInstruction] [nvarchar](2) COLLATE Latin1_General_CI_AS NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[DisbursementRequestPaymentDetails]  WITH CHECK ADD  CONSTRAINT [EDisbursementRequest_DisbursementRequestPaymentDetails] FOREIGN KEY([DisbursementRequestId])
REFERENCES [dbo].[DisbursementRequests] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[DisbursementRequestPaymentDetails] CHECK CONSTRAINT [EDisbursementRequest_DisbursementRequestPaymentDetails]
GO
ALTER TABLE [dbo].[DisbursementRequestPaymentDetails]  WITH CHECK ADD  CONSTRAINT [EDisbursementRequestPaymentDetail_Contact] FOREIGN KEY([ContactId])
REFERENCES [dbo].[PartyContacts] ([Id])
GO
ALTER TABLE [dbo].[DisbursementRequestPaymentDetails] CHECK CONSTRAINT [EDisbursementRequestPaymentDetail_Contact]
GO
ALTER TABLE [dbo].[DisbursementRequestPaymentDetails]  WITH CHECK ADD  CONSTRAINT [EDisbursementRequestPaymentDetail_Payee] FOREIGN KEY([PayeeId])
REFERENCES [dbo].[Vendors] ([Id])
GO
ALTER TABLE [dbo].[DisbursementRequestPaymentDetails] CHECK CONSTRAINT [EDisbursementRequestPaymentDetail_Payee]
GO
ALTER TABLE [dbo].[DisbursementRequestPaymentDetails]  WITH CHECK ADD  CONSTRAINT [EDisbursementRequestPaymentDetail_PayFromAccount] FOREIGN KEY([PayFromAccountId])
REFERENCES [dbo].[BankAccounts] ([Id])
GO
ALTER TABLE [dbo].[DisbursementRequestPaymentDetails] CHECK CONSTRAINT [EDisbursementRequestPaymentDetail_PayFromAccount]
GO
ALTER TABLE [dbo].[DisbursementRequestPaymentDetails]  WITH CHECK ADD  CONSTRAINT [EDisbursementRequestPaymentDetail_RemitTo] FOREIGN KEY([RemitToId])
REFERENCES [dbo].[RemitToes] ([Id])
GO
ALTER TABLE [dbo].[DisbursementRequestPaymentDetails] CHECK CONSTRAINT [EDisbursementRequestPaymentDetail_RemitTo]
GO
