CREATE TYPE [dbo].[LoanPaymentScheduleHistory] AS TABLE(
	[OriginalPaymentStructure] [nvarchar](14) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[OriginalPaymentAmount_Amount] [decimal](16, 2) NOT NULL,
	[OriginalPaymentAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[EndDate] [date] NULL,
	[IsActive] [bit] NOT NULL,
	[LoanPaymentScheduleId] [bigint] NOT NULL,
	[LoanFinanceId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
