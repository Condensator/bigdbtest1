SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DeferredTaxes](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[TaxBookName] [nvarchar](7) COLLATE Latin1_General_CI_AS NULL,
	[TaxDepreciationSystem] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[FiscalYear] [decimal](4, 0) NOT NULL,
	[Date] [date] NOT NULL,
	[TaxableIncomeTax_Amount] [decimal](16, 2) NOT NULL,
	[TaxableIncomeTax_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[TaxableIncomeBook_Amount] [decimal](16, 2) NOT NULL,
	[TaxableIncomeBook_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[BookDepreciation_Amount] [decimal](16, 2) NOT NULL,
	[BookDepreciation_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[TaxDepreciation_Amount] [decimal](16, 2) NOT NULL,
	[TaxDepreciation_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IncomeTaxExpense_Amount] [decimal](16, 2) NOT NULL,
	[IncomeTaxExpense_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IncomeTaxPayable_Amount] [decimal](16, 2) NOT NULL,
	[IncomeTaxPayable_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[YTDDeferredTax_Amount] [decimal](16, 2) NOT NULL,
	[YTDDeferredTax_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsGLPosted] [bit] NOT NULL,
	[IsReprocess] [bit] NOT NULL,
	[IsAccounting] [bit] NOT NULL,
	[IsScheduled] [bit] NOT NULL,
	[AccumDefTaxLiabBalance_Amount] [decimal](16, 2) NOT NULL,
	[AccumDefTaxLiabBalance_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[TaxIncome_Amount] [decimal](16, 2) NOT NULL,
	[TaxIncome_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[BookIncome_Amount] [decimal](16, 2) NOT NULL,
	[BookIncome_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[DefTaxLiabBalance_Amount] [decimal](16, 2) NOT NULL,
	[DefTaxLiabBalance_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[MTDDeferredTax_Amount] [decimal](16, 2) NOT NULL,
	[MTDDeferredTax_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ContractId] [bigint] NOT NULL,
	[GLTemplateId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[DeferredTaxes]  WITH CHECK ADD  CONSTRAINT [EDeferredTax_Contract] FOREIGN KEY([ContractId])
REFERENCES [dbo].[Contracts] ([Id])
GO
ALTER TABLE [dbo].[DeferredTaxes] CHECK CONSTRAINT [EDeferredTax_Contract]
GO
ALTER TABLE [dbo].[DeferredTaxes]  WITH CHECK ADD  CONSTRAINT [EDeferredTax_GLTemplate] FOREIGN KEY([GLTemplateId])
REFERENCES [dbo].[GLTemplates] ([Id])
GO
ALTER TABLE [dbo].[DeferredTaxes] CHECK CONSTRAINT [EDeferredTax_GLTemplate]
GO
