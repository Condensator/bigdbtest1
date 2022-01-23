SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ReceiptApplicationReceivableDetails_Extract](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[ReceiptId] [bigint] NULL,
	[AmountApplied] [decimal](16, 2) NULL,
	[TaxApplied] [decimal](16, 2) NULL,
	[ReceivableDetailId] [bigint] NULL,
	[ReceivableDetailIsActive] [bit] NOT NULL,
	[ContractId] [bigint] NULL,
	[InvoiceId] [bigint] NULL,
	[JobStepInstanceId] [bigint] NULL,
	[ReceivableId] [bigint] NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RowVersion] [timestamp] NOT NULL,
	[DiscountingId] [bigint] NULL,
	[ReceiptApplicationReceivableDetailId] [bigint] NOT NULL,
	[BookAmountApplied] [decimal](16, 2) NOT NULL,
	[DumpId] [bigint] NULL,
	[PrevAmountAppliedForReApplication] [decimal](16, 2) NULL,
	[PrevBookAmountAppliedForReApplication] [decimal](16, 2) NULL,
	[PrevTaxAppliedForReApplication] [decimal](16, 2) NULL,
	[ReceiptApplicationId] [bigint] NULL,
	[PrevPrePaidForReApplication] [decimal](16, 2) NULL,
	[PrevPrePaidTaxForReApplication] [decimal](16, 2) NULL,
	[IsReApplication] [bit] NOT NULL,
	[AdjustedWithHoldingTax] [decimal](16, 2) NULL,
	[PrevAdjustedWithHoldingTaxForReApplication] [decimal](16, 2) NULL,
	[LeaseComponentAmountApplied] [decimal](16, 2) NULL,
	[NonLeaseComponentAmountApplied] [decimal](16, 2) NULL,
	[PrevLeaseComponentAmountAppliedForReApplication] [decimal](16, 2) NULL,
	[PrevNonLeaseComponentAmountAppliedForReApplication] [decimal](16, 2) NULL,
	[ReceivedTowardsInterest] [decimal](16, 2) NULL,
	[WithHoldingTaxBookAmountApplied] [decimal](16, 2) NULL,
	[PrevPrePaidLeaseComponentForReApplication] [decimal](16, 2) NULL,
	[PrevPrePaidNonLeaseComponentForReApplication] [decimal](16, 2) NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
