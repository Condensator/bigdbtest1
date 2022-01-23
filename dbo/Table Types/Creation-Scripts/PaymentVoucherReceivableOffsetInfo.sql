CREATE TYPE [dbo].[PaymentVoucherReceivableOffsetInfo] AS TABLE(
	[AmountToApply_Amount] [decimal](16, 2) NOT NULL,
	[AmountToApply_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[TaxToApply_Amount] [decimal](16, 2) NOT NULL,
	[TaxToApply_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[ReceivableId] [bigint] NOT NULL,
	[PaymentVoucherInfoId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
