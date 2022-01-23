CREATE TYPE [dbo].[ACHSchedule] AS TABLE(
	[ACHPaymentNumber] [bigint] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[PaymentType] [nvarchar](14) COLLATE Latin1_General_CI_AS NULL,
	[ACHAmount_Amount] [decimal](16, 2) NOT NULL,
	[ACHAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[SettlementDate] [date] NULL,
	[Status] [nvarchar](17) COLLATE Latin1_General_CI_AS NOT NULL,
	[StopPayment] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[IsPreACHNotificationCreated] [bit] NOT NULL,
	[FileGenerationDate] [date] NULL,
	[ReceivableId] [bigint] NULL,
	[ACHAccountId] [bigint] NULL,
	[BankAccountPaymentThresholdId] [bigint] NULL,
	[ContractBillingId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
