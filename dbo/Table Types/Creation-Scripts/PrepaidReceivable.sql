CREATE TYPE [dbo].[PrepaidReceivable] AS TABLE(
	[PrePaidAmount_Amount] [decimal](16, 2) NOT NULL,
	[PrePaidAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[PrePaidTaxAmount_Amount] [decimal](16, 2) NOT NULL,
	[PrePaidTaxAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[FinancingPrePaidAmount_Amount] [decimal](16, 2) NOT NULL,
	[FinancingPrePaidAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[ReceiptId] [bigint] NULL,
	[ReceivableId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
