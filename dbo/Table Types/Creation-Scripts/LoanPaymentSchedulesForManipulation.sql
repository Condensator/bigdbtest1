CREATE TYPE [dbo].[LoanPaymentSchedulesForManipulation] AS TABLE(
	[Identifier] [bigint] NULL,
	[StartDate] [date] NULL,
	[EndDate] [date] NULL,
	[AccrualEndDate] [date] NULL,
	[DueDate] [date] NULL,
	[BeginBalance] [decimal](16, 2) NULL,
	[Amount] [decimal](16, 2) NULL,
	[EndBalance] [decimal](16, 2) NULL,
	[Principal] [decimal](16, 2) NULL,
	[Interest] [decimal](16, 2) NULL,
	[PaymentStructure] [nvarchar](20) COLLATE Latin1_General_CI_AS NULL,
	[PaymentType] [nvarchar](20) COLLATE Latin1_General_CI_AS NULL,
	[PaymentNumber] [bigint] NULL,
	[Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[IsFromReceiptPosting] [bit] NULL,
	[LoanFinanceId] [bigint] NULL,
	[IsNew] [bit] NULL,
	[PaymentScheduleId] [bigint] NULL,
	[CustomerId] [bigint] NULL,
	[IsPostMaturity] [bit] NULL,
	[IsSystemGenerated] [bit] NULL
)
GO
