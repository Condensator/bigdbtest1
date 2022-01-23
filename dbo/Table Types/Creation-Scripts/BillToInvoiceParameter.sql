CREATE TYPE [dbo].[BillToInvoiceParameter] AS TABLE(
	[IsActive] [bit] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[AllowBlending] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[InvoiceGroupingParameterId] [bigint] NOT NULL,
	[BlendWithReceivableTypeId] [bigint] NULL,
	[ReceivableTypeLabelId] [bigint] NULL,
	[ReceivableTypeLanguageLabelId] [bigint] NULL,
	[BillToId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
