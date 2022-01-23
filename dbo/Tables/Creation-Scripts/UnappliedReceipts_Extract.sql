SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[UnappliedReceipts_Extract](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[ReceiptId] [bigint] NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[Currency] [nvarchar](5) COLLATE Latin1_General_CI_AS NULL,
	[BankAccountId] [bigint] NULL,
	[CurrentAmountApplied] [decimal](16, 2) NOT NULL,
	[AllocationReceiptId] [bigint] NULL,
	[OriginalReceiptBalance] [decimal](16, 2) NOT NULL,
	[ReceiptAllocationId] [bigint] NULL,
	[OriginalAllocationAmountApplied] [decimal](16, 2) NOT NULL,
	[EntityType] [nvarchar](14) COLLATE Latin1_General_CI_AS NULL,
	[ContractId] [bigint] NULL,
	[DiscountingId] [bigint] NULL,
	[CustomerId] [bigint] NULL,
	[LegalEntityId] [bigint] NULL,
	[LineOfBusinessId] [bigint] NULL,
	[CostCenterId] [bigint] NULL,
	[InstrumentTypeId] [bigint] NULL,
	[BranchId] [bigint] NULL,
	[ContractLegalEntityId] [bigint] NULL,
	[AcquisitionId] [nvarchar](12) COLLATE Latin1_General_CI_AS NULL,
	[DealProductTypeId] [bigint] NULL,
	[ReceiptGLTemplateId] [bigint] NOT NULL,
	[JobStepInstanceId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
