SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[InsurancePolicyCoverageDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[PerOccurrenceAmount_Amount] [decimal](16, 2) NOT NULL,
	[PerOccurrenceAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[AggregateAmount_Amount] [decimal](16, 2) NOT NULL,
	[AggregateAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[PerOccurrenceDeductible_Amount] [decimal](16, 2) NOT NULL,
	[PerOccurrenceDeductible_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[AggregateDeductible_Amount] [decimal](16, 2) NOT NULL,
	[AggregateDeductible_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[CoverageTypeConfigId] [bigint] NOT NULL,
	[InsurancePolicyId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[InsurancePolicyCoverageDetails]  WITH CHECK ADD  CONSTRAINT [EInsurancePolicy_InsurancePolicyCoverageDetails] FOREIGN KEY([InsurancePolicyId])
REFERENCES [dbo].[InsurancePolicies] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[InsurancePolicyCoverageDetails] CHECK CONSTRAINT [EInsurancePolicy_InsurancePolicyCoverageDetails]
GO
ALTER TABLE [dbo].[InsurancePolicyCoverageDetails]  WITH CHECK ADD  CONSTRAINT [EInsurancePolicyCoverageDetail_CoverageTypeConfig] FOREIGN KEY([CoverageTypeConfigId])
REFERENCES [dbo].[CoverageTypeConfigs] ([Id])
GO
ALTER TABLE [dbo].[InsurancePolicyCoverageDetails] CHECK CONSTRAINT [EInsurancePolicyCoverageDetail_CoverageTypeConfig]
GO
