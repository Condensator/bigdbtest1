CREATE TYPE [dbo].[NonAccrualContractDetails_Extract] AS TABLE(
	[ContractId] [bigint] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[SequenceNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[PartyNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[LegalEntityId] [bigint] NOT NULL,
	[LegalEntityNumber] [nvarchar](20) COLLATE Latin1_General_CI_AS NULL,
	[LeaseFinanceId] [bigint] NULL,
	[CommencementDate] [date] NULL,
	[MaturityDate] [date] NULL,
	[ContractType] [nvarchar](14) COLLATE Latin1_General_CI_AS NULL,
	[ContractCurrencyCode] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[LeaseContractType] [nvarchar](16) COLLATE Latin1_General_CI_AS NULL,
	[HoldingStatus] [nvarchar](13) COLLATE Latin1_General_CI_AS NULL,
	[SyndicationType] [nvarchar](16) COLLATE Latin1_General_CI_AS NULL,
	[AccountingStandard] [nvarchar](12) COLLATE Latin1_General_CI_AS NULL,
	[CanRecognizeDeferredRentalIncome] [bit] NULL,
	[InstrumentTypeId] [bigint] NOT NULL,
	[LineOfBusinessId] [bigint] NOT NULL,
	[CostCenterId] [bigint] NOT NULL,
	[IsOverTermLease] [bit] NOT NULL,
	[IsFloatRateLease] [bit] NOT NULL,
	[DealProductTypeId] [bigint] NULL,
	[PostDate] [date] NULL,
	[BranchId] [bigint] NULL,
	[AcquisitionId] [nvarchar](20) COLLATE Latin1_General_CI_AS NULL,
	[BookingGLTemplateId] [bigint] NOT NULL,
	[IncomeGLTemplateId] [bigint] NOT NULL,
	[OTPIncomeGLTemplateId] [bigint] NULL,
	[FixedTermReceivableCodeGLTemplateId] [bigint] NOT NULL,
	[OTPReceivableCodeGLTemplateId] [bigint] NULL,
	[SupplementalReceivableCodeGLTemplateId] [bigint] NULL,
	[FloatRateIncomeGLTemplateId] [bigint] NULL,
	[FloatRateARReceivableGLTemplateId] [bigint] NULL,
	[SalesTaxRemittanceMethod] [nvarchar](12) COLLATE Latin1_General_CI_AS NULL,
	[ReceivableAmendmentType] [nvarchar](20) COLLATE Latin1_General_CI_AS NULL,
	[NonAccrualTemplateId] [bigint] NULL,
	[NonAccrualDate] [date] NULL,
	[AccountingDate] [date] NULL,
	[BillingSuppressed] [bit] NOT NULL,
	[DoubtfulCollectability] [bit] NOT NULL,
	[NonAccrualId] [bigint] NULL,
	[NonAccrualContractId] [bigint] NULL,
	[JobStepInstanceId] [bigint] NULL,
	[ChunkId] [bigint] NULL,
	[IsFailed] [bit] NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO