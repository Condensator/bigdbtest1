SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TaxDepAmortizationDetailForecasts](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[BonusDepreciationAmount_Amount] [decimal](16, 2) NOT NULL,
	[BonusDepreciationAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[DepreciationEndDate] [date] NULL,
	[FirstYearTaxDepreciationForecast_Amount] [decimal](16, 2) NOT NULL,
	[FirstYearTaxDepreciationForecast_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[LastYearTaxDepreciationForecast_Amount] [decimal](16, 2) NOT NULL,
	[LastYearTaxDepreciationForecast_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[TaxDepreciationTemplateDetailId] [bigint] NOT NULL,
	[CurrencyId] [bigint] NULL,
	[TaxDepAmortizationId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[TaxDepAmortizationDetailForecasts]  WITH CHECK ADD  CONSTRAINT [ETaxDepAmortizationDetailForecast_Currency] FOREIGN KEY([CurrencyId])
REFERENCES [dbo].[Currencies] ([Id])
GO
ALTER TABLE [dbo].[TaxDepAmortizationDetailForecasts] CHECK CONSTRAINT [ETaxDepAmortizationDetailForecast_Currency]
GO
ALTER TABLE [dbo].[TaxDepAmortizationDetailForecasts]  WITH CHECK ADD  CONSTRAINT [ETaxDepAmortizationDetailForecast_TaxDepreciationTemplateDetail] FOREIGN KEY([TaxDepreciationTemplateDetailId])
REFERENCES [dbo].[TaxDepTemplateDetails] ([Id])
GO
ALTER TABLE [dbo].[TaxDepAmortizationDetailForecasts] CHECK CONSTRAINT [ETaxDepAmortizationDetailForecast_TaxDepreciationTemplateDetail]
GO
