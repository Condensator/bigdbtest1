CREATE TYPE [dbo].[ReceiptReceivableDetailMigration_Extract] AS TABLE(
	[ReceiptReceivableMigrationId] [bigint] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[PaymentNumber] [int] NULL,
	[ReceivableType] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[FunderPartyNumber] [nvarchar](20) COLLATE Latin1_General_CI_AS NULL,
	[PaymentType] [nvarchar](28) COLLATE Latin1_General_CI_AS NULL,
	[DueDate] [date] NOT NULL,
	[AmountToApply_Amount] [decimal](16, 2) NULL,
	[AmountToApply_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[TaxAmountToApply_Amount] [decimal](16, 2) NULL,
	[TaxAmountToApply_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[ReceiptMigrationId] [bigint] NOT NULL,
	[JobStepInstanceId] [bigint] NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
