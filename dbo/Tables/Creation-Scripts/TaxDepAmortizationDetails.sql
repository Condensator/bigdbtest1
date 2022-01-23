SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TaxDepAmortizationDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[DepreciationDate] [date] NOT NULL,
	[FiscalYear] [int] NOT NULL,
	[BeginNetBookValue_Amount] [decimal](16, 2) NOT NULL,
	[BeginNetBookValue_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[DepreciationAmount_Amount] [decimal](16, 2) NOT NULL,
	[DepreciationAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[EndNetBookValue_Amount] [decimal](16, 2) NOT NULL,
	[EndNetBookValue_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[TaxDepreciationConventionId] [bigint] NULL,
	[TaxDepreciationTemplateDetailId] [bigint] NOT NULL,
	[CurrencyId] [bigint] NULL,
	[TaxDepAmortizationDetailForecastId] [bigint] NULL,
	[TaxDepAmortizationId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[IsAccounting] [bit] NOT NULL,
	[IsSchedule] [bit] NOT NULL,
	[IsGLPosted] [bit] NOT NULL,
	[IsAdjustmentEntry] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[TaxDepAmortizationDetails]  WITH CHECK ADD  CONSTRAINT [ETaxDepAmortization_TaxDepAmortizationDetails] FOREIGN KEY([TaxDepAmortizationId])
REFERENCES [dbo].[TaxDepAmortizations] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[TaxDepAmortizationDetails] CHECK CONSTRAINT [ETaxDepAmortization_TaxDepAmortizationDetails]
GO
ALTER TABLE [dbo].[TaxDepAmortizationDetails]  WITH CHECK ADD  CONSTRAINT [ETaxDepAmortizationDetail_Currency] FOREIGN KEY([CurrencyId])
REFERENCES [dbo].[Currencies] ([Id])
GO
ALTER TABLE [dbo].[TaxDepAmortizationDetails] CHECK CONSTRAINT [ETaxDepAmortizationDetail_Currency]
GO
ALTER TABLE [dbo].[TaxDepAmortizationDetails]  WITH CHECK ADD  CONSTRAINT [ETaxDepAmortizationDetail_TaxDepreciationConvention] FOREIGN KEY([TaxDepreciationConventionId])
REFERENCES [dbo].[TaxDepConventions] ([Id])
GO
ALTER TABLE [dbo].[TaxDepAmortizationDetails] CHECK CONSTRAINT [ETaxDepAmortizationDetail_TaxDepreciationConvention]
GO
ALTER TABLE [dbo].[TaxDepAmortizationDetails]  WITH CHECK ADD  CONSTRAINT [ETaxDepAmortizationDetail_TaxDepreciationTemplateDetail] FOREIGN KEY([TaxDepreciationTemplateDetailId])
REFERENCES [dbo].[TaxDepTemplateDetails] ([Id])
GO
ALTER TABLE [dbo].[TaxDepAmortizationDetails] CHECK CONSTRAINT [ETaxDepAmortizationDetail_TaxDepreciationTemplateDetail]
GO
