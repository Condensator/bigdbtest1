CREATE TYPE [dbo].[ReceivableCode] AS TABLE(
	[Name] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[AccountingTreatment] [nvarchar](12) COLLATE Latin1_General_CI_AS NOT NULL,
	[DefaultInvoiceReceivableGroupingOption] [nvarchar](8) COLLATE Latin1_General_CI_AS NOT NULL,
	[DefaultInvoiceComment] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[Description] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[IsTaxExempt] [bit] NOT NULL,
	[IncludeInPayoffOrPaydown] [bit] NOT NULL,
	[IncludeInEAR] [bit] NOT NULL,
	[IsVatInvoice] [bit] NOT NULL,
	[IsRentalBased] [bit] NOT NULL,
	[IncludeInEARForCustomerType] [nvarchar](10) COLLATE Latin1_General_CI_AS NULL,
	[IsIncludeVATInEARForIndividual] [bit] NOT NULL,
	[ReceivableCategoryId] [bigint] NOT NULL,
	[ReceivableTypeId] [bigint] NOT NULL,
	[TaxReceivableTypeId] [bigint] NULL,
	[GLTemplateId] [bigint] NOT NULL,
	[SyndicationGLTemplateId] [bigint] NULL,
	[PortfolioId] [bigint] NOT NULL,
	[WithholdingTaxCodeId] [bigint] NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO