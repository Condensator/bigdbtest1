SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PropertyTaxCombinedTaxRates](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[TaxAreaId] [bigint] NULL,
	[TaxRate] [decimal](10, 6) NULL,
	[IsActive] [bit] NOT NULL,
	[ExemptionCode] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[AssetId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[PropertyTaxCombinedTaxRates]  WITH CHECK ADD  CONSTRAINT [EPropertyTaxCombinedTaxRate_Asset] FOREIGN KEY([AssetId])
REFERENCES [dbo].[Assets] ([Id])
GO
ALTER TABLE [dbo].[PropertyTaxCombinedTaxRates] CHECK CONSTRAINT [EPropertyTaxCombinedTaxRate_Asset]
GO
