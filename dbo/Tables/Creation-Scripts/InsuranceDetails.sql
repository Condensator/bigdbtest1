SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[InsuranceDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Number] [int] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[InsuranceType] [nvarchar](5) COLLATE Latin1_General_CI_AS NOT NULL,
	[Internal] [bit] NOT NULL,
	[Frequency] [nvarchar](10) COLLATE Latin1_General_CI_AS NOT NULL,
	[EngineCapacity] [decimal](16, 2) NOT NULL,
	[VehicleAge] [int] NOT NULL,
	[InsurancePremium_Amount] [decimal](16, 2) NOT NULL,
	[InsurancePremium_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NULL,
	[InsuranceCompanyId] [bigint] NOT NULL,
	[InsuranceAgencyId] [bigint] NOT NULL,
	[RegionConfigId] [bigint] NOT NULL,
	[ProgramAssetTypeId] [bigint] NOT NULL,
	[ReceivableCodeId] [bigint] NOT NULL,
	[QuoteId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[InsuranceDetails]  WITH CHECK ADD  CONSTRAINT [EInsuranceDetail_InsuranceAgency] FOREIGN KEY([InsuranceAgencyId])
REFERENCES [dbo].[InsuranceAgencies] ([Id])
GO
ALTER TABLE [dbo].[InsuranceDetails] CHECK CONSTRAINT [EInsuranceDetail_InsuranceAgency]
GO
ALTER TABLE [dbo].[InsuranceDetails]  WITH CHECK ADD  CONSTRAINT [EInsuranceDetail_InsuranceCompany] FOREIGN KEY([InsuranceCompanyId])
REFERENCES [dbo].[InsuranceCompanies] ([Id])
GO
ALTER TABLE [dbo].[InsuranceDetails] CHECK CONSTRAINT [EInsuranceDetail_InsuranceCompany]
GO
ALTER TABLE [dbo].[InsuranceDetails]  WITH CHECK ADD  CONSTRAINT [EInsuranceDetail_ProgramAssetType] FOREIGN KEY([ProgramAssetTypeId])
REFERENCES [dbo].[ProgramAssetTypes] ([Id])
GO
ALTER TABLE [dbo].[InsuranceDetails] CHECK CONSTRAINT [EInsuranceDetail_ProgramAssetType]
GO
ALTER TABLE [dbo].[InsuranceDetails]  WITH CHECK ADD  CONSTRAINT [EInsuranceDetail_ReceivableCode] FOREIGN KEY([ReceivableCodeId])
REFERENCES [dbo].[ReceivableCodes] ([Id])
GO
ALTER TABLE [dbo].[InsuranceDetails] CHECK CONSTRAINT [EInsuranceDetail_ReceivableCode]
GO
ALTER TABLE [dbo].[InsuranceDetails]  WITH CHECK ADD  CONSTRAINT [EInsuranceDetail_RegionConfig] FOREIGN KEY([RegionConfigId])
REFERENCES [dbo].[RegionConfigs] ([Id])
GO
ALTER TABLE [dbo].[InsuranceDetails] CHECK CONSTRAINT [EInsuranceDetail_RegionConfig]
GO
ALTER TABLE [dbo].[InsuranceDetails]  WITH CHECK ADD  CONSTRAINT [EQuote_InsuranceDetails] FOREIGN KEY([QuoteId])
REFERENCES [dbo].[Quotes] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[InsuranceDetails] CHECK CONSTRAINT [EQuote_InsuranceDetails]
GO
