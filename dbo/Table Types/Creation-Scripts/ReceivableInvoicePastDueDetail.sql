CREATE TYPE [dbo].[ReceivableInvoicePastDueDetail] AS TABLE(
	[EntityId] [bigint] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[EntityType] [nvarchar](2) COLLATE Latin1_General_CI_AS NOT NULL,
	[PastDueBalance_Amount] [decimal](16, 2) NOT NULL,
	[PastDueBalance_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[PastDueTaxBalance_Amount] [decimal](16, 2) NOT NULL,
	[PastDueTaxBalance_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[ReceivableInvoiceId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
