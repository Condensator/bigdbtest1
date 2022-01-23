SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ACHReceiptJobLogs](
	[ACHReceiptId] [bigint] NULL,
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ErrorCode] [nvarchar](4) COLLATE Latin1_General_CI_AS NULL,
	[ReceiptNumber] [nvarchar](20) COLLATE Latin1_General_CI_AS NULL,
	[SequenceNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[ACHScheduleId] [bigint] NULL,
	[ACHRunId] [bigint] NULL,
	[InvoiceNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[LegalEntityNumber] [nvarchar](20) COLLATE Latin1_General_CI_AS NULL,
	[LineofBusinessName] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[CostCenter] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[JobstepInstanceId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[ReceivableId] [bigint] NULL,
	[ReceivedDate] [date] NULL,
	[PaymentNumber] [bigint] NULL,
	[OneTimeACHId] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
