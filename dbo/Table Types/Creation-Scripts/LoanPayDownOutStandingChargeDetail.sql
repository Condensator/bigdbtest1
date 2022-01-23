CREATE TYPE [dbo].[LoanPayDownOutStandingChargeDetail] AS TABLE(
	[DueDate] [date] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ReceivableAmount_Amount] [decimal](16, 2) NOT NULL,
	[ReceivableAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[ReceivableBalance_Amount] [decimal](16, 2) NOT NULL,
	[ReceivableBalance_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[SalesTaxAmount_Amount] [decimal](16, 2) NOT NULL,
	[SalesTaxAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[SalesTaxBalance_Amount] [decimal](16, 2) NOT NULL,
	[SalesTaxBalance_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[ReceivableType] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[IncludeinInvoice] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[ReceivableId] [bigint] NOT NULL,
	[LoanPaydownId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
