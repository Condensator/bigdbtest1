SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LeaseTaxAssessmentTaxBasisTypes](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsOtherBasisType] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[TaxBasisTypeId] [bigint] NOT NULL,
	[LeaseTaxAssessmentDetailId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[LeaseTaxAssessmentTaxBasisTypes]  WITH CHECK ADD  CONSTRAINT [ELeaseTaxAssessmentDetail_LeaseTaxAssessmentTaxBasisTypes] FOREIGN KEY([LeaseTaxAssessmentDetailId])
REFERENCES [dbo].[LeaseTaxAssessmentDetails] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[LeaseTaxAssessmentTaxBasisTypes] CHECK CONSTRAINT [ELeaseTaxAssessmentDetail_LeaseTaxAssessmentTaxBasisTypes]
GO
ALTER TABLE [dbo].[LeaseTaxAssessmentTaxBasisTypes]  WITH CHECK ADD  CONSTRAINT [ELeaseTaxAssessmentTaxBasisType_TaxBasisType] FOREIGN KEY([TaxBasisTypeId])
REFERENCES [dbo].[TaxBasisTypes] ([Id])
GO
ALTER TABLE [dbo].[LeaseTaxAssessmentTaxBasisTypes] CHECK CONSTRAINT [ELeaseTaxAssessmentTaxBasisType_TaxBasisType]
GO
