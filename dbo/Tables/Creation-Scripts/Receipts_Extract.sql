SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Receipts_Extract](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[ReceiptId] [bigint] NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
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
	[IsValid] [bit] NOT NULL,
	[JobStepInstanceId] [bigint] NULL,
	[DumpId] [bigint] NULL,
	[IsNewReceipt] [bit] NOT NULL,
	[MaxDueDate] [date] NULL,
	[ContractLegalEntityId] [bigint] NULL,
	[AcquisitionId] [nvarchar](12) COLLATE Latin1_General_CI_AS NULL,
	[EntityType] [nvarchar](14) COLLATE Latin1_General_CI_AS NULL,
	[ReceiptGLTemplateId] [bigint] NOT NULL,
	[CustomerId] [bigint] NULL,
	[ReceiptAmount] [decimal](16, 2) NOT NULL,
	[BankAccountId] [bigint] NULL,
	[ReceiptApplicationId] [bigint] NULL,
	[UnallocatedDescription] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[DealProductTypeId] [bigint] NULL,
	[CurrencyId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[LegalEntityHierarchyTemplateId] [bigint] NULL,
	[ContractHierarchyTemplateId] [bigint] NULL,
	[CustomerHierarchyTemplateId] [bigint] NULL,
	[ContractLegalEntityHierarchyTemplateId] [bigint] NULL,
	[ReceiptHierarchyTemplateId] [bigint] NULL,
	[IsReceiptHierarchyProcessed] [bit] NULL,
	[ReceiptType] [nvarchar](30) COLLATE Latin1_General_CI_AS NULL,
	[SecurityDepositLiabilityAmount] [decimal](16, 2) NULL,
	[SecurityDepositLiabilityContractAmount] [decimal](16, 2) NULL,
	[SecurityDepositGLTemplateId] [bigint] NULL,
	[PPTEscrowGLTemplateId] [bigint] NULL,
	[BeforePostingReceiptId] [bigint] NULL,
	[PayOffId] [bigint] NULL,
	[PayDownId] [bigint] NULL,
	[CashTypeId] [bigint] NULL,
	[ReceiptTypeId] [bigint] NULL,
	[Comment] [nvarchar](1000) COLLATE Latin1_General_CI_AS NULL,
	[CheckNumber] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[Status] [nvarchar](15) COLLATE Latin1_General_CI_AS NULL,
	[ACHReceiptId] [bigint] NULL,
	[SourceOfError] [nvarchar](10) COLLATE Latin1_General_CI_AS NULL,
	[ReceivableTaxType] [nvarchar](8) COLLATE Latin1_General_CI_AS NULL,
	[BankName] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
