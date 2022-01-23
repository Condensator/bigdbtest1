CREATE TYPE [dbo].[ReceiptRentSharingDetails_Extract] AS TABLE(
	[ReceiptId] [bigint] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ReceivableId] [bigint] NOT NULL,
	[RentSharingPercentage] [decimal](16, 2) NOT NULL,
	[VendorId] [bigint] NOT NULL,
	[RemitToId] [bigint] NOT NULL,
	[PayableCodeId] [bigint] NOT NULL,
	[SourceType] [nvarchar](7) COLLATE Latin1_General_CI_AS NOT NULL,
	[PaidPayableAmount] [decimal](16, 2) NULL,
	[JobStepInstanceId] [bigint] NULL,
	[WithholdingTaxRate] [decimal](5, 2) NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
