CREATE TYPE [dbo].[ACHReceiptJobLog] AS TABLE(
	[ACHReceiptId] [bigint] NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ErrorCode] [nvarchar](4) COLLATE Latin1_General_CI_AS NULL,
	[ReceiptNumber] [nvarchar](20) COLLATE Latin1_General_CI_AS NULL,
	[SequenceNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[ACHScheduleId] [bigint] NULL,
	[PaymentNumber] [bigint] NULL,
	[OneTimeACHId] [bigint] NULL,
	[ACHRunId] [bigint] NULL,
	[InvoiceNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[LegalEntityNumber] [nvarchar](20) COLLATE Latin1_General_CI_AS NULL,
	[LineofBusinessName] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[CostCenter] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[ReceivableId] [bigint] NULL,
	[ReceivedDate] [date] NULL,
	[JobstepInstanceId] [bigint] NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO