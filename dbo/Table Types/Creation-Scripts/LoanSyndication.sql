CREATE TYPE [dbo].[LoanSyndication] AS TABLE(
	[RetainedPercentage] [decimal](18, 8) NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[FundedAmount_Amount] [decimal](16, 2) NOT NULL,
	[FundedAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[FundingDate] [date] NULL,
	[RentalProceedsWithholdingTaxRate] [decimal](5, 2) NULL,
	[RentalProceedsPayableCodeId] [bigint] NULL,
	[ProgressPaymentReimbursementCodeId] [bigint] NULL,
	[ScrapeReceivableCodeId] [bigint] NULL,
	[UpfrontSyndicationFeeCodeId] [bigint] NULL,
	[LoanPaydownGLTemplateId] [bigint] NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
