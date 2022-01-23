SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ACHReturn_Extract](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[ACHRunId] [bigint] NULL,
	[ACHRunDetailId] [bigint] NULL,
	[ACHRunFileId] [bigint] NULL,
	[ReceiptId] [bigint] NULL,
	[LegalEntityId] [bigint] NULL,
	[ACHScheduleId] [bigint] NULL,
	[OneTimeACHId] [bigint] NULL,
	[EntryDetailLineNumber] [bigint] NULL,
	[ReturnReasonCodeLineNumber] [bigint] NULL,
	[JobStepInstanceId] [bigint] NULL,
	[IsOneTimeACH] [bit] NULL,
	[ReceivedDate] [date] NULL,
	[ReceiptClassification] [nvarchar](23) COLLATE Latin1_General_CI_AS NULL,
	[Status] [nvarchar](15) COLLATE Latin1_General_CI_AS NULL,
	[ReceiptAmount_Amount] [decimal](16, 2) NULL,
	[ReceiptAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[ReturnFileReceiptAmount_Amount] [decimal](16, 2) NULL,
	[ReturnFileReceiptAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[EntityType] [nvarchar](14) COLLATE Latin1_General_CI_AS NULL,
	[TraceNumber] [nvarchar](20) COLLATE Latin1_General_CI_AS NULL,
	[FileName] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[ReasonCode] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[ReceiptNumber] [nvarchar](20) COLLATE Latin1_General_CI_AS NULL,
	[ReACH] [bit] NULL,
	[IsNSFChargeEligible] [bit] NULL,
	[NSFCustomerId] [bigint] NULL,
	[NSFLocationId] [bigint] NULL,
	[NSFBillToId] [bigint] NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RowVersion] [timestamp] NOT NULL,
	[GUID] [uniqueidentifier] NULL,
	[IsPending] [bit] NOT NULL,
	[CustomerBankAccountId] [bigint] NULL,
	[LegalEntityACHFailureLimit] [bigint] NULL,
	[CurrentACHFailureCount] [int] NULL,
	[CurrentOnHoldStatus] [bit] NOT NULL,
	[ContractId] [bigint] NULL,
	[AccountOnHoldCount] [int] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
