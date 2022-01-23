SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SalesTaxReceivableDetail_Extract](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[ReceivableId] [bigint] NOT NULL,
	[LeaseAssetId] [bigint] NULL,
	[CustomerLocationId] [bigint] NULL,
	[AssetLocationId] [bigint] NULL,
	[ReceivableDetailId] [bigint] NOT NULL,
	[AssetId] [bigint] NULL,
	[ReceivableDueDate] [date] NOT NULL,
	[ContractId] [bigint] NULL,
	[CustomerId] [bigint] NOT NULL,
	[EntityType] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[ExtendedPrice] [decimal](16, 2) NOT NULL,
	[Currency] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[LocationId] [bigint] NULL,
	[PreviousLocationId] [bigint] NULL,
	[ReceivableCodeId] [bigint] NOT NULL,
	[AmountBilledToDate] [decimal](16, 2) NOT NULL,
	[IsExemptAtSundry] [bit] NOT NULL,
	[PaymentScheduleId] [bigint] NULL,
	[LegalEntityId] [bigint] NOT NULL,
	[IsVertexSupported] [bit] NOT NULL,
	[StateId] [bigint] NULL,
	[InvalidErrorCode] [nvarchar](4) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[JobStepInstanceId] [bigint] NOT NULL,
	[DiscountingId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[TaxPayer] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[LegalEntityTaxRemittancePreference] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[LegalEntityName] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[GLTemplateId] [bigint] NULL,
	[AdjustmentBasisReceivableDetailId] [bigint] NULL,
	[IsOriginalReceivableDetailTaxAssessed] [bit] NULL,
	[IsAssessSalesTaxAtSKULevel] [bit] NOT NULL,
	[SourceId] [bigint] NULL,
	[SourceTable] [nvarchar](20) COLLATE Latin1_General_CI_AS NULL,
	[ReceivableTaxType] [nvarchar](8) COLLATE Latin1_General_CI_AS NULL,
	[IsRenewal] [bit] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
