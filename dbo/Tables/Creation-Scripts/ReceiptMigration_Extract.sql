SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ReceiptMigration_Extract](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[ReceiptMigrationId] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ContractSequenceNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[LegalEntityNumber] [nvarchar](20) COLLATE Latin1_General_CI_AS NOT NULL,
	[CheckNumber] [nvarchar](13) COLLATE Latin1_General_CI_AS NULL,
	[ReceiptAmount_Amount] [decimal](16, 2) NOT NULL,
	[ReceiptAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[PostDate] [date] NULL,
	[IsPureUnallocatedCash] [bit] NOT NULL,
	[TotalAmountToApply_Amount] [decimal](16, 2) NULL,
	[TotalAmountToApply_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[TotalTaxAmountToApply_Amount] [decimal](16, 2) NULL,
	[TotalTaxAmountToApply_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[CashTypeName] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[CurrencyCode] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[BankAccountNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[BankName] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[ReceiptGLTemplateName] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[ReceiptTypeName] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[UniqueIdentifier] [uniqueidentifier] NOT NULL,
	[ReceivedDate] [date] NULL,
	[IsValid] [bit] NOT NULL,
	[ErrorMessage] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[IsProcessed] [bit] NOT NULL,
	[JobStepInstanceId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[Comment] [nvarchar](1000) COLLATE Latin1_General_CI_AS NULL,
	[BankAccountBranchName] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[BankAccountBankName] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
