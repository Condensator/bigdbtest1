CREATE TYPE [dbo].[PayableTypeInvoiceConfig] AS TABLE(
	[PaymentType] [nvarchar](28) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ApplicableForTaxType] [nvarchar](8) COLLATE Latin1_General_CI_AS NOT NULL,
	[ApplicableForBlending] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[InvoiceLanguageLabel] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
