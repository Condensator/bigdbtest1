SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ACHReceipts](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[ReceiptId] [bigint] NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[IsActive] [bit] NOT NULL,
	[Currency] [nvarchar](5) COLLATE Latin1_General_CI_AS NULL,
	[ReceiptClassification] [nvarchar](23) COLLATE Latin1_General_CI_AS NULL,
	[LegalEntityId] [bigint] NULL,
	[LineOfBusinessId] [bigint] NULL,
	[CostCenterId] [bigint] NULL,
	[InstrumentTypeId] [bigint] NULL,
	[BranchId] [bigint] NULL,
	[ContractId] [bigint] NULL,
	[EntityType] [nvarchar](14) COLLATE Latin1_General_CI_AS NULL,
	[ReceiptGLTemplateId] [bigint] NOT NULL,
	[CustomerId] [bigint] NULL,
	[ReceiptAmount] [decimal](16, 2) NOT NULL,
	[BankAccountId] [bigint] NULL,
	[InActivateBankAccountId] [bigint] NULL,
	[ReceiptApplicationId] [bigint] NULL,
	[CurrencyId] [bigint] NOT NULL,
	[ReceiptType] [nvarchar](30) COLLATE Latin1_General_CI_AS NULL,
	[ReceiptTypeId] [bigint] NOT NULL,
	[CheckNumber] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[SettlementDate] [date] NULL,
	[Status] [nvarchar](15) COLLATE Latin1_General_CI_AS NULL,
	[UnallocatedAmount] [decimal](16, 2) NOT NULL,
	[TraceNumber] [nvarchar](20) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsOneTimeACH] [bit] NOT NULL,
	[ACHEntryDetailId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[OneTimeACHId] [bigint] NULL,
	[ExtractReceiptId] [bigint] NULL,
	[UpdateJobStepInstanceId] [bigint] NOT NULL,
	[CashTypeId] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
