CREATE TYPE [dbo].[ACHReceiptApplicationReceivableDetail] AS TABLE(
	[AmountApplied] [decimal](16, 2) NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[TaxApplied] [decimal](16, 2) NOT NULL,
	[ReceivableDetailId] [bigint] NULL,
	[InvoiceId] [bigint] NULL,
	[ReceivableId] [bigint] NULL,
	[ScheduleId] [bigint] NOT NULL,
	[ContractId] [bigint] NULL,
	[DiscountingId] [bigint] NULL,
	[ACHReceiptId] [bigint] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[LeaseComponentAmountApplied] [decimal](16, 2) NULL,
	[NonLeaseComponentAmountApplied] [decimal](16, 2) NULL,
	[BookAmountApplied] [decimal](16, 2) NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
