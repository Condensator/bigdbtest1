CREATE TYPE [dbo].[LoanPaymentScheduleToUpdate] AS TABLE(
	[BeginBalance] [decimal](16, 2) NULL,
	[EndBalance] [decimal](16, 2) NULL,
	[Interest] [decimal](16, 2) NULL,
	[Principal] [decimal](16, 2) NULL,
	[Amount] [decimal](16, 2) NULL,
	[PaymentStructure] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[PaymentScheduleId] [bigint] NULL
)
GO
