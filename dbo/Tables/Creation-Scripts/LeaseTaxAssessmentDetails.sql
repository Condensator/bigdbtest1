SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LeaseTaxAssessmentDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[SalesTaxRate] [decimal](10, 6) NOT NULL,
	[SalesTaxAmount_Amount] [decimal](16, 2) NOT NULL,
	[SalesTaxAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[OtherBasisTypesAvailable] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[UpfrontTaxMode] [nvarchar](6) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[TaxBasisTypeId] [bigint] NULL,
	[LocationId] [bigint] NULL,
	[AssetTypeId] [bigint] NULL,
	[LeaseFinanceId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[Exemption] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[PrepaidUpfrontTax_Amount] [decimal](16, 2) NOT NULL,
	[PrepaidUpfrontTax_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[UpfrontTaxPayable_Amount] [decimal](16, 2) NOT NULL,
	[UpfrontTaxPayable_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[TaxCodeId] [bigint] NULL,
	[TaxTypeId] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[LeaseTaxAssessmentDetails]  WITH CHECK ADD  CONSTRAINT [ELeaseFinance_LeaseTaxAssessmentDetails] FOREIGN KEY([LeaseFinanceId])
REFERENCES [dbo].[LeaseFinances] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[LeaseTaxAssessmentDetails] CHECK CONSTRAINT [ELeaseFinance_LeaseTaxAssessmentDetails]
GO
ALTER TABLE [dbo].[LeaseTaxAssessmentDetails]  WITH CHECK ADD  CONSTRAINT [ELeaseTaxAssessmentDetail_AssetType] FOREIGN KEY([AssetTypeId])
REFERENCES [dbo].[AssetTypes] ([Id])
GO
ALTER TABLE [dbo].[LeaseTaxAssessmentDetails] CHECK CONSTRAINT [ELeaseTaxAssessmentDetail_AssetType]
GO
ALTER TABLE [dbo].[LeaseTaxAssessmentDetails]  WITH CHECK ADD  CONSTRAINT [ELeaseTaxAssessmentDetail_Location] FOREIGN KEY([LocationId])
REFERENCES [dbo].[Locations] ([Id])
GO
ALTER TABLE [dbo].[LeaseTaxAssessmentDetails] CHECK CONSTRAINT [ELeaseTaxAssessmentDetail_Location]
GO
ALTER TABLE [dbo].[LeaseTaxAssessmentDetails]  WITH CHECK ADD  CONSTRAINT [ELeaseTaxAssessmentDetail_TaxBasisType] FOREIGN KEY([TaxBasisTypeId])
REFERENCES [dbo].[TaxBasisTypes] ([Id])
GO
ALTER TABLE [dbo].[LeaseTaxAssessmentDetails] CHECK CONSTRAINT [ELeaseTaxAssessmentDetail_TaxBasisType]
GO
ALTER TABLE [dbo].[LeaseTaxAssessmentDetails]  WITH CHECK ADD  CONSTRAINT [ELeaseTaxAssessmentDetail_TaxCode] FOREIGN KEY([TaxCodeId])
REFERENCES [dbo].[TaxCodes] ([Id])
GO
ALTER TABLE [dbo].[LeaseTaxAssessmentDetails] CHECK CONSTRAINT [ELeaseTaxAssessmentDetail_TaxCode]
GO
ALTER TABLE [dbo].[LeaseTaxAssessmentDetails]  WITH CHECK ADD  CONSTRAINT [ELeaseTaxAssessmentDetail_TaxType] FOREIGN KEY([TaxTypeId])
REFERENCES [dbo].[TaxTypes] ([Id])
GO
ALTER TABLE [dbo].[LeaseTaxAssessmentDetails] CHECK CONSTRAINT [ELeaseTaxAssessmentDetail_TaxType]
GO
