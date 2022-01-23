SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ReversalReceivableDetail_Extract](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[ReceivableTaxId] [bigint] NULL,
	[IsCashPosted] [bit] NOT NULL,
	[ReceivableDetailId] [bigint] NOT NULL,
	[Currency] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[TaxAreaId] [bigint] NULL,
	[Cost] [decimal](16, 2) NOT NULL,
	[ExtendedPrice] [decimal](16, 2) NOT NULL,
	[FairMarketValue] [decimal](16, 2) NOT NULL,
	[TaxBasisType] [nvarchar](5) COLLATE Latin1_General_CI_AS NULL,
	[AssetId] [bigint] NULL,
	[LocationId] [bigint] NULL,
	[DueDate] [date] NOT NULL,
	[ReceivableId] [bigint] NOT NULL,
	[ReceivableCodeId] [bigint] NULL,
	[IsInvoiced] [bit] NOT NULL,
	[IsExemptAtLease] [bit] NOT NULL,
	[IsExemptAtAsset] [bit] NOT NULL,
	[IsExemptAtSundry] [bit] NOT NULL,
	[Company] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[Product] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[ContractType] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[LeaseType] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[LeaseTerm] [decimal](18, 8) NULL,
	[TitleTransferCode] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[TransactionCode] [nvarchar](4) COLLATE Latin1_General_CI_AS NULL,
	[AmountBilledToDate] [decimal](16, 2) NOT NULL,
	[AssetLocationId] [bigint] NULL,
	[ToState] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[FromState] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[SundryReceivableCode] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[IsExemptAtReceivableCode] [bit] NOT NULL,
	[TransactionType] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[ReceivableType] [nvarchar](21) COLLATE Latin1_General_CI_AS NULL,
	[IsRental] [bit] NOT NULL,
	[CustomerId] [bigint] NOT NULL,
	[ContractId] [bigint] NULL,
	[DiscountingId] [bigint] NULL,
	[LegalEntityId] [bigint] NULL,
	[LegalEntityName] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[GLFinancialOpenPeriodFromDate] [date] NULL,
	[GLFinancialOpenPeriodToDate] [date] NULL,
	[EntityType] [nvarchar](2) COLLATE Latin1_General_CI_AS NULL,
	[ErrorCode] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[IsVertexSupported] [bit] NOT NULL,
	[CustomerName] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[ContractTypeValue] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[LeaseUniqueId] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[ReceivableTaxDetailId] [bigint] NULL,
	[ReceivableTaxDetailRowVersion] [bigint] NULL,
	[ReceivableTaxRowVersion] [bigint] NULL,
	[ReceivableDetailRowVersion] [bigint] NULL,
	[AssetLocationRowVersion] [bigint] NULL,
	[JobStepInstanceId] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RowVersion] [timestamp] NOT NULL,
	[VoucherNumbers] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[UpfrontTaxSundryId] [bigint] NULL,
	[AcquisitionLocationId] [bigint] NULL,
	[SalesTaxRemittanceResponsibility] [nvarchar](8) COLLATE Latin1_General_CI_AS NULL,
	[IsAssessSalesTaxAtSKULevel] [bit] NOT NULL,
	[UpfrontTaxAssessedInLegacySystem] [bit] NOT NULL,
	[ReceivableTaxType] [nvarchar](8) COLLATE Latin1_General_CI_AS NULL,
	[PaymentScheduleId] [bigint] NULL,
	[BusCode] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[AssetType] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO