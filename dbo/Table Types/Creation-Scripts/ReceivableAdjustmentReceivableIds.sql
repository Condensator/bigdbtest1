CREATE TYPE [dbo].[ReceivableAdjustmentReceivableIds] AS TABLE(
	[ReceivableId] [bigint] NULL,
	[PaymentScheduleId] [bigint] NULL,
	[ReverseTaxAssessedFlag] [bit] NULL
)
GO
