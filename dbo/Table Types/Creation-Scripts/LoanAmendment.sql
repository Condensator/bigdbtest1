CREATE TYPE [dbo].[LoanAmendment] AS TABLE(
	[QuoteName] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[AmendmentType] [nvarchar](31) COLLATE Latin1_General_CI_AS NOT NULL,
	[QuoteStatus] [nvarchar](9) COLLATE Latin1_General_CI_AS NOT NULL,
	[AmendmentDate] [date] NULL,
	[AccountingDate] [date] NULL,
	[QuoteGoodThroughDate] [date] NULL,
	[Comment] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[PostDate] [date] NULL,
	[IsTDR] [bit] NOT NULL,
	[AmendmentAtInception] [bit] NOT NULL,
	[ReceivableAmendmentType] [nvarchar](20) COLLATE Latin1_General_CI_AS NULL,
	[IsRestructureDateConfirmed] [bit] NOT NULL,
	[TDRReason] [nvarchar](24) COLLATE Latin1_General_CI_AS NULL,
	[FinalAcceptanceDate] [date] NULL,
	[IsLienFilingRequired] [bit] NOT NULL,
	[IsLienFilingException] [bit] NOT NULL,
	[LienExceptionComment] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[LienExceptionReason] [nvarchar](24) COLLATE Latin1_General_CI_AS NULL,
	[PreRestructureDateLoanNBV_Amount] [decimal](16, 2) NOT NULL,
	[PreRestructureDateLoanNBV_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[PostRestructureDateLoanNBV_Amount] [decimal](16, 2) NOT NULL,
	[PostRestructureDateLoanNBV_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[PreRestructureFAS91Balance_Amount] [decimal](16, 2) NOT NULL,
	[PreRestructureFAS91Balance_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[PostRestructureFAS91Balance_Amount] [decimal](16, 2) NOT NULL,
	[PostRestructureFAS91Balance_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[NetWritedown_Amount] [decimal](16, 2) NOT NULL,
	[NetWritedown_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsModified] [bit] NOT NULL,
	[SourceId] [bigint] NULL,
	[AmendmentReasonComment] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[LoanFinanceId] [bigint] NOT NULL,
	[LoanPaymentScheduleId] [bigint] NULL,
	[DealProductTypeId] [bigint] NULL,
	[DealTypeId] [bigint] NULL,
	[AmendmentReasonId] [bigint] NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO