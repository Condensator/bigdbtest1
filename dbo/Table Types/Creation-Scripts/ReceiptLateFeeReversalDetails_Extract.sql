CREATE TYPE [dbo].[ReceiptLateFeeReversalDetails_Extract] AS TABLE(
	[ReceiptId] [bigint] NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ContractId] [bigint] NULL,
	[LateFeeReceivableId] [bigint] NULL,
	[AssessedTillDate] [date] NULL,
	[ReceivableId] [bigint] NULL,
	[ReceiptNumbers] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[InvoiceNumbers] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[JobStepInstanceId] [bigint] NULL,
	[AssessmentId] [bigint] NULL,
	[CurrencyCode] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[ContractType] [nvarchar](14) COLLATE Latin1_General_CI_AS NULL,
	[ReceivableAmendmentType] [nvarchar](20) COLLATE Latin1_General_CI_AS NULL,
	[InvoiceId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
