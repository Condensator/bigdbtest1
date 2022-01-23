SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BankAccounts](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[AccountName] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[IBAN] [nvarchar](34) COLLATE Latin1_General_CI_AS NULL,
	[IsOneTimeACHOnly] [bit] NOT NULL,
	[IsExpired] [bit] NOT NULL,
	[IsOwnersAuthorizationReceived] [bit] NOT NULL,
	[AuthorizationDate] [date] NULL,
	[IsPrimaryACH] [bit] NOT NULL,
	[ExternalPackageCheckBookID] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[DefaultToAP] [bit] NOT NULL,
	[AccountType] [nvarchar](9) COLLATE Latin1_General_CI_AS NULL,
	[GLSegmentValue] [nvarchar](12) COLLATE Latin1_General_CI_AS NULL,
	[RemittanceType] [nvarchar](5) COLLATE Latin1_General_CI_AS NULL,
	[DefaultAccountFor] [nvarchar](5) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[BankBranchId] [bigint] NULL,
	[CurrencyId] [bigint] NULL,
	[ReceiptGLTemplateId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[IsFromCustomerPortal] [bit] NOT NULL,
	[LastFourDigitAccountNumber] [nvarchar](4) COLLATE Latin1_General_CI_AS NULL,
	[AccountNumber_CT] [varbinary](max) NULL,
	[UniqueIdentifier] [nvarchar](30) COLLATE Latin1_General_CI_AS NULL,
	[BankAccountCategoryId] [bigint] NULL,
	[PaymentProfileId] [nvarchar](20) COLLATE Latin1_General_CI_AS NULL,
	[AutomatedPaymentMethod] [nvarchar](10) COLLATE Latin1_General_CI_AS NULL,
	[LegalEntityAccountNumber] [nvarchar](22) COLLATE Latin1_General_CI_AS NULL,
	[ACHFailureCount] [int] NULL,
	[OnHold] [bit] NOT NULL,
	[AccountOnHoldCount] [int] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[BankAccounts]  WITH CHECK ADD  CONSTRAINT [EBankAccount_BankAccountCategory] FOREIGN KEY([BankAccountCategoryId])
REFERENCES [dbo].[BankAccountCategories] ([Id])
GO
ALTER TABLE [dbo].[BankAccounts] CHECK CONSTRAINT [EBankAccount_BankAccountCategory]
GO
ALTER TABLE [dbo].[BankAccounts]  WITH CHECK ADD  CONSTRAINT [EBankAccount_BankBranch] FOREIGN KEY([BankBranchId])
REFERENCES [dbo].[BankBranches] ([Id])
GO
ALTER TABLE [dbo].[BankAccounts] CHECK CONSTRAINT [EBankAccount_BankBranch]
GO
ALTER TABLE [dbo].[BankAccounts]  WITH CHECK ADD  CONSTRAINT [EBankAccount_Currency] FOREIGN KEY([CurrencyId])
REFERENCES [dbo].[Currencies] ([Id])
GO
ALTER TABLE [dbo].[BankAccounts] CHECK CONSTRAINT [EBankAccount_Currency]
GO
ALTER TABLE [dbo].[BankAccounts]  WITH CHECK ADD  CONSTRAINT [EBankAccount_ReceiptGLTemplate] FOREIGN KEY([ReceiptGLTemplateId])
REFERENCES [dbo].[GLTemplates] ([Id])
GO
ALTER TABLE [dbo].[BankAccounts] CHECK CONSTRAINT [EBankAccount_ReceiptGLTemplate]
GO
