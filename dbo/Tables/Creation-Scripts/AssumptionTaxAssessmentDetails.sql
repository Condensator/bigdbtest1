SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AssumptionTaxAssessmentDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[SalesTaxRate] [decimal](9, 5) NOT NULL,
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
	[AssumptionId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[IsDummy] [bit] NOT NULL,
	[TaxCodeId] [bigint] NULL,
	[TaxTypeId] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[AssumptionTaxAssessmentDetails]  WITH CHECK ADD  CONSTRAINT [EAssumption_AssumptionTaxAssessmentDetails] FOREIGN KEY([AssumptionId])
REFERENCES [dbo].[Assumptions] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[AssumptionTaxAssessmentDetails] CHECK CONSTRAINT [EAssumption_AssumptionTaxAssessmentDetails]
GO
ALTER TABLE [dbo].[AssumptionTaxAssessmentDetails]  WITH CHECK ADD  CONSTRAINT [EAssumptionTaxAssessmentDetail_AssetType] FOREIGN KEY([AssetTypeId])
REFERENCES [dbo].[AssetTypes] ([Id])
GO
ALTER TABLE [dbo].[AssumptionTaxAssessmentDetails] CHECK CONSTRAINT [EAssumptionTaxAssessmentDetail_AssetType]
GO
ALTER TABLE [dbo].[AssumptionTaxAssessmentDetails]  WITH CHECK ADD  CONSTRAINT [EAssumptionTaxAssessmentDetail_Location] FOREIGN KEY([LocationId])
REFERENCES [dbo].[Locations] ([Id])
GO
ALTER TABLE [dbo].[AssumptionTaxAssessmentDetails] CHECK CONSTRAINT [EAssumptionTaxAssessmentDetail_Location]
GO
ALTER TABLE [dbo].[AssumptionTaxAssessmentDetails]  WITH CHECK ADD  CONSTRAINT [EAssumptionTaxAssessmentDetail_TaxBasisType] FOREIGN KEY([TaxBasisTypeId])
REFERENCES [dbo].[TaxBasisTypes] ([Id])
GO
ALTER TABLE [dbo].[AssumptionTaxAssessmentDetails] CHECK CONSTRAINT [EAssumptionTaxAssessmentDetail_TaxBasisType]
GO
ALTER TABLE [dbo].[AssumptionTaxAssessmentDetails]  WITH CHECK ADD  CONSTRAINT [EAssumptionTaxAssessmentDetail_TaxCode] FOREIGN KEY([TaxCodeId])
REFERENCES [dbo].[TaxCodes] ([Id])
GO
ALTER TABLE [dbo].[AssumptionTaxAssessmentDetails] CHECK CONSTRAINT [EAssumptionTaxAssessmentDetail_TaxCode]
GO
ALTER TABLE [dbo].[AssumptionTaxAssessmentDetails]  WITH CHECK ADD  CONSTRAINT [EAssumptionTaxAssessmentDetail_TaxType] FOREIGN KEY([TaxTypeId])
REFERENCES [dbo].[TaxTypes] ([Id])
GO
ALTER TABLE [dbo].[AssumptionTaxAssessmentDetails] CHECK CONSTRAINT [EAssumptionTaxAssessmentDetail_TaxType]
GO
