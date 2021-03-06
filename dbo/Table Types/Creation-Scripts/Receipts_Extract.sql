CREATE TYPE [dbo].[Receipts_Extract] AS TABLE(
	[ReceiptId] [bigint] NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[BeforePostingReceiptId] [bigint] NULL,
	[ReceiptNumber] [nvarchar](20) COLLATE Latin1_General_CI_AS NULL,
	[Currency] [nvarchar](5) COLLATE Latin1_General_CI_AS NULL,
	[PostDate] [date] NULL,
	[ReceivedDate] [date] NULL,
	[ReceiptClassification] [nvarchar](23) COLLATE Latin1_General_CI_AS NULL,
	[LegalEntityId] [bigint] NULL,
	[LineOfBusinessId] [bigint] NULL,
	[CostCenterId] [bigint] NULL,
	[InstrumentTypeId] [bigint] NULL,
	[BranchId] [bigint] NULL,
	[ContractId] [bigint] NULL,
	[DiscountingId] [bigint] NULL,
	[ReceiptBatchId] [bigint] NULL,
	[ReceiptHierarchyTemplateId] [bigint] NULL,
	[LegalEntityHierarchyTemplateId] [bigint] NULL,
	[ContractHierarchyTemplateId] [bigint] NULL,
	[CustomerHierarchyTemplateId] [bigint] NULL,
	[ContractLegalEntityHierarchyTemplateId] [bigint] NULL,
	[IsReceiptHierarchyProcessed] [bit] NULL,
	[IsValid] [bit] NOT NULL,
	[JobStepInstanceId] [bigint] NULL,
	[DumpId] [bigint] NULL,
	[IsNewReceipt] [bit] NOT NULL,
	[MaxDueDate] [date] NULL,
	[ContractLegalEntityId] [bigint] NULL,
	[AcquisitionId] [nvarchar](12) COLLATE Latin1_General_CI_AS NULL,
	[EntityType] [nvarchar](14) COLLATE Latin1_General_CI_AS NULL,
	[SourceOfError] [nvarchar](10) COLLATE Latin1_General_CI_AS NULL,
	[ReceiptGLTemplateId] [bigint] NOT NULL,
	[CustomerId] [bigint] NULL,
	[ReceiptAmount] [decimal](16, 2) NOT NULL,
	[BankAccountId] [bigint] NULL,
	[ReceiptApplicationId] [bigint] NULL,
	[UnallocatedDescription] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[DealProductTypeId] [bigint] NULL,
	[CurrencyId] [bigint] NOT NULL,
	[ReceiptType] [nvarchar](30) COLLATE Latin1_General_CI_AS NULL,
	[SecurityDepositGLTemplateId] [bigint] NULL,
	[PPTEscrowGLTemplateId] [bigint] NULL,
	[SecurityDepositLiabilityAmount] [decimal](16, 2) NULL,
	[SecurityDepositLiabilityContractAmount] [decimal](16, 2) NULL,
	[PayOffId] [bigint] NULL,
	[PayDownId] [bigint] NULL,
	[CashTypeId] [bigint] NULL,
	[ReceiptTypeId] [bigint] NULL,
	[Comment] [nvarchar](1000) COLLATE Latin1_General_CI_AS NULL,
	[CheckNumber] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[Status] [nvarchar](15) COLLATE Latin1_General_CI_AS NULL,
	[ACHReceiptId] [bigint] NULL,
	[ReceivableTaxType] [nvarchar](8) COLLATE Latin1_General_CI_AS NULL,
	[BankName] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
