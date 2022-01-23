CREATE TYPE [dbo].[ACHSchedulesToPersist] AS TABLE(
	[Identifier] [bigint] NULL,
	[Status] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[ACHAccountId] [bigint] NULL,
	[SettlementDate] [date] NULL,
	[PaymentType] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[ACHPaymentNumber] [bigint] NULL,
	[ContractBillingId] [bigint] NULL,
	[Amount] [decimal](16, 2) NULL,
	[Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[BankAccountPaymentThresholdId] [bigint] NULL
)
GO
