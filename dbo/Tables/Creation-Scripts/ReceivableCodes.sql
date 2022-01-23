SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ReceivableCodes](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[AccountingTreatment] [nvarchar](12) COLLATE Latin1_General_CI_AS NOT NULL,
	[DefaultInvoiceReceivableGroupingOption] [nvarchar](8) COLLATE Latin1_General_CI_AS NOT NULL,
	[DefaultInvoiceComment] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[Description] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[IsTaxExempt] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ReceivableCategoryId] [bigint] NOT NULL,
	[ReceivableTypeId] [bigint] NOT NULL,
	[GLTemplateId] [bigint] NOT NULL,
	[SyndicationGLTemplateId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[IncludeInPayoffOrPaydown] [bit] NOT NULL,
	[PortfolioId] [bigint] NOT NULL,
	[WithholdingTaxCodeId] [bigint] NULL,
	[IncludeInEAR] [bit] NOT NULL,
	[TaxReceivableTypeId] [bigint] NULL,
	[IsVatInvoice] [bit] NOT NULL,
	[IsRentalBased] [bit] NOT NULL,
	[IncludeInEARForCustomerType] [nvarchar](10) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsIncludeVATInEARForIndividual] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ReceivableCodes]  WITH CHECK ADD  CONSTRAINT [EReceivableCode_GLTemplate] FOREIGN KEY([GLTemplateId])
REFERENCES [dbo].[GLTemplates] ([Id])
GO
ALTER TABLE [dbo].[ReceivableCodes] CHECK CONSTRAINT [EReceivableCode_GLTemplate]
GO
ALTER TABLE [dbo].[ReceivableCodes]  WITH CHECK ADD  CONSTRAINT [EReceivableCode_Portfolio] FOREIGN KEY([PortfolioId])
REFERENCES [dbo].[Portfolios] ([Id])
GO
ALTER TABLE [dbo].[ReceivableCodes] CHECK CONSTRAINT [EReceivableCode_Portfolio]
GO
ALTER TABLE [dbo].[ReceivableCodes]  WITH CHECK ADD  CONSTRAINT [EReceivableCode_ReceivableCategory] FOREIGN KEY([ReceivableCategoryId])
REFERENCES [dbo].[ReceivableCategories] ([Id])
GO
ALTER TABLE [dbo].[ReceivableCodes] CHECK CONSTRAINT [EReceivableCode_ReceivableCategory]
GO
ALTER TABLE [dbo].[ReceivableCodes]  WITH CHECK ADD  CONSTRAINT [EReceivableCode_ReceivableType] FOREIGN KEY([ReceivableTypeId])
REFERENCES [dbo].[ReceivableTypes] ([Id])
GO
ALTER TABLE [dbo].[ReceivableCodes] CHECK CONSTRAINT [EReceivableCode_ReceivableType]
GO
ALTER TABLE [dbo].[ReceivableCodes]  WITH CHECK ADD  CONSTRAINT [EReceivableCode_SyndicationGLTemplate] FOREIGN KEY([SyndicationGLTemplateId])
REFERENCES [dbo].[GLTemplates] ([Id])
GO
ALTER TABLE [dbo].[ReceivableCodes] CHECK CONSTRAINT [EReceivableCode_SyndicationGLTemplate]
GO
ALTER TABLE [dbo].[ReceivableCodes]  WITH CHECK ADD  CONSTRAINT [EReceivableCode_TaxReceivableType] FOREIGN KEY([TaxReceivableTypeId])
REFERENCES [dbo].[TaxReceivableTypes] ([Id])
GO
ALTER TABLE [dbo].[ReceivableCodes] CHECK CONSTRAINT [EReceivableCode_TaxReceivableType]
GO
ALTER TABLE [dbo].[ReceivableCodes]  WITH CHECK ADD  CONSTRAINT [EReceivableCode_WithholdingTaxCode] FOREIGN KEY([WithholdingTaxCodeId])
REFERENCES [dbo].[WithholdingTaxCodes] ([Id])
GO
ALTER TABLE [dbo].[ReceivableCodes] CHECK CONSTRAINT [EReceivableCode_WithholdingTaxCode]
GO
