SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ReceiptLateFeeReversalDetails_Extract](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[ReceiptId] [bigint] NULL,
	[LateFeeReceivableId] [bigint] NULL,
	[ReceivableId] [bigint] NULL,
	[ReceiptNumbers] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[InvoiceNumbers] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[JobStepInstanceId] [bigint] NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RowVersion] [timestamp] NOT NULL,
	[AssessedTillDate] [date] NULL,
	[AssessmentId] [bigint] NULL,
	[ContractType] [nvarchar](14) COLLATE Latin1_General_CI_AS NULL,
	[ReceivableAmendmentType] [nvarchar](20) COLLATE Latin1_General_CI_AS NULL,
	[CurrencyCode] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[InvoiceId] [bigint] NOT NULL,
	[ContractId] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
