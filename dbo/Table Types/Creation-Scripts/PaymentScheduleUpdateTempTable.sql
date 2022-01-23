CREATE TYPE [dbo].[PaymentScheduleUpdateTempTable] AS TABLE(
	[OldPaymentScheduleId] [bigint] NULL,
	[NewPaymentScheduleId] [bigint] NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL
)
GO
