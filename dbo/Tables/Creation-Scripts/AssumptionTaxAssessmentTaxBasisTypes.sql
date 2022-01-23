SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AssumptionTaxAssessmentTaxBasisTypes](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsOtherBasisType] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[TaxBasisTypeId] [bigint] NULL,
	[AssumptionTaxAssessmentDetailId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[AssumptionTaxAssessmentTaxBasisTypes]  WITH CHECK ADD  CONSTRAINT [EAssumptionTaxAssessmentDetail_AssumptionTaxAssessmentTaxBasisTypes] FOREIGN KEY([AssumptionTaxAssessmentDetailId])
REFERENCES [dbo].[AssumptionTaxAssessmentDetails] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[AssumptionTaxAssessmentTaxBasisTypes] CHECK CONSTRAINT [EAssumptionTaxAssessmentDetail_AssumptionTaxAssessmentTaxBasisTypes]
GO
ALTER TABLE [dbo].[AssumptionTaxAssessmentTaxBasisTypes]  WITH CHECK ADD  CONSTRAINT [EAssumptionTaxAssessmentTaxBasisType_TaxBasisType] FOREIGN KEY([TaxBasisTypeId])
REFERENCES [dbo].[TaxBasisTypes] ([Id])
GO
ALTER TABLE [dbo].[AssumptionTaxAssessmentTaxBasisTypes] CHECK CONSTRAINT [EAssumptionTaxAssessmentTaxBasisType_TaxBasisType]
GO
