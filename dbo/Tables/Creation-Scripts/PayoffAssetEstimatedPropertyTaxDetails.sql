SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PayoffAssetEstimatedPropertyTaxDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Year] [decimal](4, 0) NOT NULL,
	[EstimatedPropertyTax_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[EstimatedPropertyTax_Amount] [decimal](16, 2) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[PayoffAssetId] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[PayoffAssetEstimatedPropertyTaxDetails]  WITH CHECK ADD  CONSTRAINT [EPayoffAsset_PayoffAssetEstimatedPropertyTaxDetails] FOREIGN KEY([PayoffAssetId])
REFERENCES [dbo].[PayoffAssets] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[PayoffAssetEstimatedPropertyTaxDetails] CHECK CONSTRAINT [EPayoffAsset_PayoffAssetEstimatedPropertyTaxDetails]
GO
