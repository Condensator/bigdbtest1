SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ACHSchedules](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[ACHPaymentNumber] [bigint] NOT NULL,
	[PaymentType] [nvarchar](14) COLLATE Latin1_General_CI_AS NULL,
	[ACHAmount_Amount] [decimal](16, 2) NOT NULL,
	[ACHAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[SettlementDate] [date] NULL,
	[Status] [nvarchar](17) COLLATE Latin1_General_CI_AS NOT NULL,
	[StopPayment] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ReceivableId] [bigint] NULL,
	[ACHAccountId] [bigint] NULL,
	[ContractBillingId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[BankAccountPaymentThresholdId] [bigint] NULL,
	[IsPreACHNotificationCreated] [bit] NOT NULL,
	[FileGenerationDate] [date] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ACHSchedules]  WITH CHECK ADD  CONSTRAINT [EACHSchedule_ACHAccount] FOREIGN KEY([ACHAccountId])
REFERENCES [dbo].[BankAccounts] ([Id])
GO
ALTER TABLE [dbo].[ACHSchedules] CHECK CONSTRAINT [EACHSchedule_ACHAccount]
GO
ALTER TABLE [dbo].[ACHSchedules]  WITH CHECK ADD  CONSTRAINT [EACHSchedule_BankAccountPaymentThreshold] FOREIGN KEY([BankAccountPaymentThresholdId])
REFERENCES [dbo].[ContractBankAccountPaymentThresholds] ([Id])
GO
ALTER TABLE [dbo].[ACHSchedules] CHECK CONSTRAINT [EACHSchedule_BankAccountPaymentThreshold]
GO
ALTER TABLE [dbo].[ACHSchedules]  WITH CHECK ADD  CONSTRAINT [EACHSchedule_Receivable] FOREIGN KEY([ReceivableId])
REFERENCES [dbo].[Receivables] ([Id])
GO
ALTER TABLE [dbo].[ACHSchedules] CHECK CONSTRAINT [EACHSchedule_Receivable]
GO
ALTER TABLE [dbo].[ACHSchedules]  WITH CHECK ADD  CONSTRAINT [EContractBilling_ACHSchedules] FOREIGN KEY([ContractBillingId])
REFERENCES [dbo].[ContractBillings] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[ACHSchedules] CHECK CONSTRAINT [EContractBilling_ACHSchedules]
GO
