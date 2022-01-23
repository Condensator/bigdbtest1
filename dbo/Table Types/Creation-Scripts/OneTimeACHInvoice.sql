CREATE TYPE [dbo].[OneTimeACHInvoice] AS TABLE(
	[AmountApplied_Amount] [decimal](16, 2) NULL,
	[AmountApplied_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[IsActive] [bit] NOT NULL,
	[IsStatementInvoice] [bit] NOT NULL,
	[Status] [nvarchar](18) COLLATE Latin1_General_CI_AS NOT NULL,
	[ReceivableInvoiceId] [bigint] NOT NULL,
	[OneTimeACHId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
