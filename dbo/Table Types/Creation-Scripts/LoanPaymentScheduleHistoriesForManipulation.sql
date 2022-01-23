CREATE TYPE [dbo].[LoanPaymentScheduleHistoriesForManipulation] AS TABLE(
	[EndDate] [date] NULL,
	[OriginalPayment] [decimal](16, 2) NULL,
	[OriginalPaymentStructure] [nvarchar](20) COLLATE Latin1_General_CI_AS NULL,
	[Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[LoanFinanceId] [bigint] NULL,
	[PaymentScheduleId] [bigint] NULL,
	[PaymentScheduleIdentifier] [bigint] NULL
)
GO
