SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CustomerBankAccountPaymentThresholds](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[PaymentThreshold] [bit] NOT NULL,
	[PaymentThresholdAmount_Amount] [decimal](16, 2) NOT NULL,
	[PaymentThresholdAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[EmailId] [nvarchar](70) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[BankAccountId] [bigint] NOT NULL,
	[CustomerId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[ThresholdExceededEmailTemplateId] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CustomerBankAccountPaymentThresholds]  WITH CHECK ADD  CONSTRAINT [ECustomer_CustomerBankAccountPaymentThresholds] FOREIGN KEY([CustomerId])
REFERENCES [dbo].[Customers] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CustomerBankAccountPaymentThresholds] CHECK CONSTRAINT [ECustomer_CustomerBankAccountPaymentThresholds]
GO
ALTER TABLE [dbo].[CustomerBankAccountPaymentThresholds]  WITH CHECK ADD  CONSTRAINT [ECustomerBankAccountPaymentThreshold_BankAccount] FOREIGN KEY([BankAccountId])
REFERENCES [dbo].[BankAccounts] ([Id])
GO
ALTER TABLE [dbo].[CustomerBankAccountPaymentThresholds] CHECK CONSTRAINT [ECustomerBankAccountPaymentThreshold_BankAccount]
GO
ALTER TABLE [dbo].[CustomerBankAccountPaymentThresholds]  WITH CHECK ADD  CONSTRAINT [ECustomerBankAccountPaymentThreshold_ThresholdExceededEmailTemplate] FOREIGN KEY([ThresholdExceededEmailTemplateId])
REFERENCES [dbo].[EmailTemplates] ([Id])
GO
ALTER TABLE [dbo].[CustomerBankAccountPaymentThresholds] CHECK CONSTRAINT [ECustomerBankAccountPaymentThreshold_ThresholdExceededEmailTemplate]
GO
