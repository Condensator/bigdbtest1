SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ACHEntryDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[ACHEntryDetailRecordTypeCode] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[ACHEntryDetailTransactionCode] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[CustomerBankDebitCode] [bigint] NULL,
	[CustomerBankAccountACHRoutingNumber] [nvarchar](20) COLLATE Latin1_General_CI_AS NULL,
	[CustomerBankAccountNumber_CT] [varbinary](48) NULL,
	[ACHAmount] [decimal](16, 2) NULL,
	[EntityId] [bigint] NULL,
	[PartyName] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[ACHEntryDetailAddendaRecordIndicator] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[OrigDFIID] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[TraceNumber] [bigint] NULL,
	[PAPEntryDetailRecordTypeCode] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[PAPEntryDetailPaymentNumber] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[PAPEntryDetailLanguageCode] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[PAPEntryDetailDestinationCountry] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[PAPEntryDetailOptionalRecordIndicator] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[PAPEntryDetailClientShortName] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[Currency] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[CustomerBankAccountId] [bigint] NULL,
	[CostCenterId] [bit] NOT NULL,
	[JobStepInstanceId] [bigint] NULL,
	[ACHScheduleExtractIds] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[ACHBatchHeaderId] [bigint] NOT NULL,
	[EntryDetailId] [bigint] NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ACHEntryDetails]  WITH CHECK ADD  CONSTRAINT [EACHBatchHeader_ACHEntryDetails] FOREIGN KEY([ACHBatchHeaderId])
REFERENCES [dbo].[ACHBatchHeaders] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[ACHEntryDetails] CHECK CONSTRAINT [EACHBatchHeader_ACHEntryDetails]
GO
