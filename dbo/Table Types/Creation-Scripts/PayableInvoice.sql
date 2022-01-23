CREATE TYPE [dbo].[PayableInvoice] AS TABLE(
	[InvoiceNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[OriginalInvoiceNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[InvoiceDate] [date] NULL,
	[DueDate] [date] NOT NULL,
	[Alias] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[Status] [nvarchar](9) COLLATE Latin1_General_CI_AS NOT NULL,
	[InvoiceTotal_Amount] [decimal](16, 2) NOT NULL,
	[InvoiceTotal_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[TotalAssetCost_Amount] [decimal](16, 2) NOT NULL,
	[TotalAssetCost_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[NumberOfAssets] [int] NOT NULL,
	[IsForeignCurrency] [bit] NOT NULL,
	[InitialExchangeRate] [decimal](20, 10) NULL,
	[Balance_Amount] [decimal](16, 2) NULL,
	[Balance_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[AllowCreateAssets] [bit] NOT NULL,
	[PostDate] [date] NULL,
	[Comment] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[IsOtherCostDistributionRequired] [bit] NOT NULL,
	[IsAttachedInTransaction] [bit] NOT NULL,
	[IsSystemGenerated] [bit] NOT NULL,
	[ContractType] [nvarchar](14) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsSalesLeaseBack] [bit] NOT NULL,
	[Revise] [bit] NOT NULL,
	[SourceTransaction] [nvarchar](20) COLLATE Latin1_General_CI_AS NOT NULL,
	[OriginalExchangeRate] [decimal](20, 10) NULL,
	[IsInvalidPayableInvoice] [bit] NOT NULL,
	[PayableInvoiceDocumentInstance_Source] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[PayableInvoiceDocumentInstance_Type] [nvarchar](5) COLLATE Latin1_General_CI_AS NULL,
	[PayableInvoiceDocumentInstance_Content] [varbinary](82) NULL,
	[VendorNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[CustomerNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[AssetCostWithholdingTaxRate] [decimal](5, 2) NULL,
	[DisbursementWithholdingTaxRate] [decimal](5, 2) NULL,
	[IsOriginalInvoice] [bit] NOT NULL,
	[OriginalInvoiceDate] [date] NULL,
	[LegalEntityId] [bigint] NOT NULL,
	[VendorId] [bigint] NOT NULL,
	[AssetCostPayableCodeId] [bigint] NULL,
	[CustomerId] [bigint] NULL,
	[ContractId] [bigint] NULL,
	[CurrencyId] [bigint] NOT NULL,
	[ContractCurrencyId] [bigint] NULL,
	[GLJournalId] [bigint] NULL,
	[ReversalGLJournalId] [bigint] NULL,
	[RemitToId] [bigint] NULL,
	[ParentPayableInvoiceId] [bigint] NULL,
	[InstrumentTypeId] [bigint] NULL,
	[LineofBusinessId] [bigint] NULL,
	[CostCenterId] [bigint] NULL,
	[BranchId] [bigint] NULL,
	[CountryId] [bigint] NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
