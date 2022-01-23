SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ReceiptOTPReceivables_Extract](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[ReceivableDetailId] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[AssetId] [bigint] NOT NULL,
	[SequenceNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[AssetComponentType] [nvarchar](7) COLLATE Latin1_General_CI_AS NULL,
	[Balance] [decimal](16, 2) NOT NULL,
	[ReceiptApplicationReceivableDetailId] [bigint] NOT NULL,
	[AmountApplied] [decimal](16, 2) NOT NULL,
	[ReceiptId] [bigint] NOT NULL,
	[ReceivableIncomeType] [nvarchar](16) COLLATE Latin1_General_CI_AS NOT NULL,
	[ReceivableId] [bigint] NOT NULL,
	[ReceivableDueDate] [date] NOT NULL,
	[ReceivableBalance] [decimal](16, 2) NOT NULL,
	[PaymentScheduleId] [bigint] NOT NULL,
	[LeaseFinanceId] [bigint] NOT NULL,
	[LegalEntityId] [bigint] NOT NULL,
	[InstrumentTypeId] [bigint] NOT NULL,
	[CostCenterId] [bigint] NOT NULL,
	[ContractId] [bigint] NOT NULL,
	[BranchId] [bigint] NULL,
	[IsNonAccrual] [bit] NOT NULL,
	[NonAccrualDate] [date] NULL,
	[LineofBusinessId] [bigint] NOT NULL,
	[IncomeGLTemplateId] [bigint] NOT NULL,
	[TotalRentalAmount] [decimal](16, 2) NOT NULL,
	[TotalDepreciationAmount] [decimal](16, 2) NOT NULL,
	[JobStepInstanceId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[AmountAppliedForDepreciation] [decimal](16, 2) NOT NULL,
	[IsReApplication] [bit] NOT NULL,
	[IsAdjustmentReceivableDetail] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
