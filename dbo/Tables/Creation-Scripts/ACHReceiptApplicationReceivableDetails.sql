SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ACHReceiptApplicationReceivableDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[AmountApplied] [decimal](16, 2) NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[TaxApplied] [decimal](16, 2) NOT NULL,
	[ReceivableDetailId] [bigint] NULL,
	[InvoiceId] [bigint] NULL,
	[ReceivableId] [bigint] NULL,
	[ContractId] [bigint] NULL,
	[DiscountingId] [bigint] NULL,
	[ScheduleId] [bigint] NOT NULL,
	[ACHReceiptId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[LeaseComponentAmountApplied] [decimal](16, 2) NULL,
	[NonLeaseComponentAmountApplied] [decimal](16, 2) NULL,
	[BookAmountApplied] [decimal](16, 2) NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
