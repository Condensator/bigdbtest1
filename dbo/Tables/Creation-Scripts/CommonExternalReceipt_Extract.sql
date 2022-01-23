SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CommonExternalReceipt_Extract](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[LegalEntityNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[EntityType] [nvarchar](14) COLLATE Latin1_General_CI_AS NULL,
	[EntityId] [bigint] NULL,
	[Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[ReceiptType] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[InvoiceNumber] [nvarchar](20) COLLATE Latin1_General_CI_AS NULL,
	[ReceiptAmount] [decimal](16, 2) NULL,
	[ReceivedDate] [date] NULL,
	[BankAccount] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[CheckNumber] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[NameOnCheck] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[BankName] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[CheckDate] [date] NULL,
	[Comment] [nvarchar](1000) COLLATE Latin1_General_CI_AS NULL,
	[CashType] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[PaymentMode] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[LineOfBusiness] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[InstrumentType] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[BankBranchName] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[CostCenter] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[GUID] [uniqueidentifier] NULL,
	[ReceivableInvoiceId] [bigint] NULL,
	[JobStepInstanceId] [bigint] NULL,
	[IsValid] [bit] NOT NULL,
	[ReceiptId] [bigint] NULL,
	[IsFullPosting] [bit] NOT NULL,
	[CreateUnallocatedReceipt] [bit] NOT NULL,
	[BankAccountId] [bigint] NULL,
	[LegalEntityId] [bigint] NULL,
	[ContractLegalEntityId] [bigint] NULL,
	[LineOfBusinessId] [bigint] NULL,
	[CostCenterId] [bigint] NULL,
	[InstrumentTypeId] [bigint] NULL,
	[CurrencyId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[IsApplyCredit] [bit] NOT NULL,
	[ApplyByReceivable] [bit] NOT NULL,
	[Status] [nvarchar](15) COLLATE Latin1_General_CI_AS NULL,
	[DumpId] [bigint] NULL,
	[PartyNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
