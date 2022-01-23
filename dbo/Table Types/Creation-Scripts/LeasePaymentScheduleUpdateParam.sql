CREATE TYPE [dbo].[LeasePaymentScheduleUpdateParam] AS TABLE(
	[PaymentScheduleId] [bigint] NULL,
	[Amount_Amount] [decimal](16, 2) NULL,
	[Amount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL
)
GO
