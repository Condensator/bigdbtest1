SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TaxRateDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Rate] [decimal](10, 6) NOT NULL,
	[EffectiveDate] [date] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[TaxRateId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[TaxRateVersioningId] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[TaxRateDetails]  WITH CHECK ADD  CONSTRAINT [ETaxRate_TaxRateDetails] FOREIGN KEY([TaxRateId])
REFERENCES [dbo].[TaxRates] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[TaxRateDetails] CHECK CONSTRAINT [ETaxRate_TaxRateDetails]
GO
ALTER TABLE [dbo].[TaxRateDetails]  WITH CHECK ADD  CONSTRAINT [ETaxRateDetail_TaxRateVersioning] FOREIGN KEY([TaxRateVersioningId])
REFERENCES [dbo].[TaxRateVersionings] ([Id])
GO
ALTER TABLE [dbo].[TaxRateDetails] CHECK CONSTRAINT [ETaxRateDetail_TaxRateVersioning]
GO
