SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TaxDepRates](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[Country] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[System] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Method] [nvarchar](34) COLLATE Latin1_General_CI_AS NOT NULL,
	[RecoveryPeriod] [decimal](3, 1) NOT NULL,
	[PropertyClassNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[ActivationDate] [date] NOT NULL,
	[DeactivationDate] [date] NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[TaxDepreciationConventionId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[CapitalCostAllowanceClassId] [bigint] NULL,
	[SpecifiedInterestRateIndexId] [bigint] NULL,
	[PortfolioId] [bigint] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[TaxDepRates]  WITH CHECK ADD  CONSTRAINT [ETaxDepRate_CapitalCostAllowanceClass] FOREIGN KEY([CapitalCostAllowanceClassId])
REFERENCES [dbo].[CapitalCostAllowanceClasses] ([Id])
GO
ALTER TABLE [dbo].[TaxDepRates] CHECK CONSTRAINT [ETaxDepRate_CapitalCostAllowanceClass]
GO
ALTER TABLE [dbo].[TaxDepRates]  WITH CHECK ADD  CONSTRAINT [ETaxDepRate_Portfolio] FOREIGN KEY([PortfolioId])
REFERENCES [dbo].[Portfolios] ([Id])
GO
ALTER TABLE [dbo].[TaxDepRates] CHECK CONSTRAINT [ETaxDepRate_Portfolio]
GO
ALTER TABLE [dbo].[TaxDepRates]  WITH CHECK ADD  CONSTRAINT [ETaxDepRate_SpecifiedInterestRateIndex] FOREIGN KEY([SpecifiedInterestRateIndexId])
REFERENCES [dbo].[FloatRateIndexes] ([Id])
GO
ALTER TABLE [dbo].[TaxDepRates] CHECK CONSTRAINT [ETaxDepRate_SpecifiedInterestRateIndex]
GO
ALTER TABLE [dbo].[TaxDepRates]  WITH CHECK ADD  CONSTRAINT [ETaxDepRate_TaxDepreciationConvention] FOREIGN KEY([TaxDepreciationConventionId])
REFERENCES [dbo].[TaxDepConventions] ([Id])
GO
ALTER TABLE [dbo].[TaxDepRates] CHECK CONSTRAINT [ETaxDepRate_TaxDepreciationConvention]
GO
