SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ACHBatchHeaders](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[ACHBatchHeaderRecordTypeCode] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[ACHBatchHeaderServiceClassCode] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[PrivateLableName] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[TaxID] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[SEC] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[ACHBatchHeaderCompanyEntryDescription] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[Settlementdate] [date] NULL,
	[ACHBatchHeaderOriginatorStatusCode] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[OrigDFIID] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[JobStepInstanceId] [bigint] NULL,
	[ACHBatchControlRecordTypeCode] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[ACHBatchControlServiceClassCode] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[GenerateBalancedACH] [bit] NOT NULL,
	[ReceiptLegalEntityBankAccountId] [bigint] NULL,
	[ReceiptLegalEntityBankAccountCreditCode] [bigint] NULL,
	[ReceiptLegalEntityBankAccountNumber_CT] [varbinary](48) NULL,
	[ReceiptLegalEntityBankAccountACHRoutingNumber] [nvarchar](20) COLLATE Latin1_General_CI_AS NULL,
	[Origin] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[OriginName] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[FileHeaderId] [bigint] NULL,
	[BatchHeaderId] [bigint] NULL,
	[ACHFileHeaderId] [bigint] NOT NULL,
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
ALTER TABLE [dbo].[ACHBatchHeaders]  WITH CHECK ADD  CONSTRAINT [EACHFileHeader_ACHBatchHeaders] FOREIGN KEY([ACHFileHeaderId])
REFERENCES [dbo].[ACHFileHeaders] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[ACHBatchHeaders] CHECK CONSTRAINT [EACHFileHeader_ACHBatchHeaders]
GO
