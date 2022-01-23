CREATE TYPE [dbo].[ReceiptPassThroughReceivables_Extract] AS TABLE(
	[ReceivableId] [bigint] NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[PassThroughPayableDueDate] [date] NULL,
	[TotalPayableAmount] [decimal](16, 2) NULL,
	[PaidPayableAmount] [decimal](16, 2) NULL,
	[VendorId] [bigint] NULL,
	[PayableRemitToId] [bigint] NULL,
	[PayableCodeId] [bigint] NULL,
	[SourceId] [bigint] NULL,
	[SourceTable] [nvarchar](24) COLLATE Latin1_General_CI_AS NULL,
	[PassThroughPercent] [decimal](16, 2) NULL,
	[JobStepInstanceId] [bigint] NULL,
	[WithholdingTaxRate] [decimal](5, 2) NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
