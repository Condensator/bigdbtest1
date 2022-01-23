SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ReceiptReceivableDetailMigration_Extract](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[ReceiptReceivableMigrationId] [bigint] NOT NULL,
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
	[RowVersion] [timestamp] NOT NULL,
	[JobStepInstanceId] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
