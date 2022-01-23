SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ReceivableTaxSKUImpositions](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[ExemptionType] [nvarchar](27) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ExemptionRate] [decimal](10, 6) NOT NULL,
	[ExemptionAmount_Amount] [decimal](16, 2) NOT NULL,
	[ExemptionAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[TaxableBasisAmount_Amount] [decimal](16, 2) NOT NULL,
	[TaxableBasisAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[AppliedTaxRate] [decimal](10, 6) NOT NULL,
	[Amount_Amount] [decimal](16, 2) NOT NULL,
	[Amount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[ExternalTaxImpositionType] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[AssetSKUId] [bigint] NOT NULL,
	[TaxTypeId] [bigint] NULL,
	[ExternalJurisdictionLevelId] [bigint] NULL,
	[ReceivableTaxDetailId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[TaxBasisType] [nvarchar](5) COLLATE Latin1_General_CI_AS NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ReceivableTaxSKUImpositions]  WITH CHECK ADD  CONSTRAINT [EReceivableTaxDetail_ReceivableTaxSKUImpositions] FOREIGN KEY([ReceivableTaxDetailId])
REFERENCES [dbo].[ReceivableTaxDetails] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[ReceivableTaxSKUImpositions] CHECK CONSTRAINT [EReceivableTaxDetail_ReceivableTaxSKUImpositions]
GO
ALTER TABLE [dbo].[ReceivableTaxSKUImpositions]  WITH CHECK ADD  CONSTRAINT [EReceivableTaxSKUImposition_AssetSKU] FOREIGN KEY([AssetSKUId])
REFERENCES [dbo].[AssetSKUs] ([Id])
GO
ALTER TABLE [dbo].[ReceivableTaxSKUImpositions] CHECK CONSTRAINT [EReceivableTaxSKUImposition_AssetSKU]
GO
ALTER TABLE [dbo].[ReceivableTaxSKUImpositions]  WITH CHECK ADD  CONSTRAINT [EReceivableTaxSKUImposition_ExternalJurisdictionLevel] FOREIGN KEY([ExternalJurisdictionLevelId])
REFERENCES [dbo].[TaxAuthorityConfigs] ([Id])
GO
ALTER TABLE [dbo].[ReceivableTaxSKUImpositions] CHECK CONSTRAINT [EReceivableTaxSKUImposition_ExternalJurisdictionLevel]
GO
ALTER TABLE [dbo].[ReceivableTaxSKUImpositions]  WITH CHECK ADD  CONSTRAINT [EReceivableTaxSKUImposition_TaxType] FOREIGN KEY([TaxTypeId])
REFERENCES [dbo].[TaxTypes] ([Id])
GO
ALTER TABLE [dbo].[ReceivableTaxSKUImpositions] CHECK CONSTRAINT [EReceivableTaxSKUImposition_TaxType]
GO
