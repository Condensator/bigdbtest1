SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LegalEntityBankAccounts](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[BankAccountId] [bigint] NOT NULL,
	[ACHOperatorConfigId] [bigint] NULL,
	[LegalEntityId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[ACISCustomerNumber] [nvarchar](10) COLLATE Latin1_General_CI_AS NULL,
	[SourceofInput] [nvarchar](8) COLLATE Latin1_General_CI_AS NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[LegalEntityBankAccounts]  WITH CHECK ADD  CONSTRAINT [ELegalEntity_LegalEntityBankAccounts] FOREIGN KEY([LegalEntityId])
REFERENCES [dbo].[LegalEntities] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[LegalEntityBankAccounts] CHECK CONSTRAINT [ELegalEntity_LegalEntityBankAccounts]
GO
ALTER TABLE [dbo].[LegalEntityBankAccounts]  WITH CHECK ADD  CONSTRAINT [ELegalEntityBankAccount_ACHOperatorConfig] FOREIGN KEY([ACHOperatorConfigId])
REFERENCES [dbo].[ACHOperatorConfigs] ([Id])
GO
ALTER TABLE [dbo].[LegalEntityBankAccounts] CHECK CONSTRAINT [ELegalEntityBankAccount_ACHOperatorConfig]
GO
ALTER TABLE [dbo].[LegalEntityBankAccounts]  WITH CHECK ADD  CONSTRAINT [ELegalEntityBankAccount_BankAccount] FOREIGN KEY([BankAccountId])
REFERENCES [dbo].[BankAccounts] ([Id])
GO
ALTER TABLE [dbo].[LegalEntityBankAccounts] CHECK CONSTRAINT [ELegalEntityBankAccount_BankAccount]
GO
