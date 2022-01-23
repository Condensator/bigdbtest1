SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ReceivableTaxImpositions](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[ExemptionType] [nvarchar](27) COLLATE Latin1_General_CI_AS NULL,
	[ExemptionRate] [decimal](10, 6) NOT NULL,
	[ExemptionAmount_Amount] [decimal](16, 2) NOT NULL,
	[ExemptionAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[TaxableBasisAmount_Amount] [decimal](16, 2) NOT NULL,
	[TaxableBasisAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[AppliedTaxRate] [decimal](10, 6) NOT NULL,
	[Amount_Amount] [decimal](16, 2) NOT NULL,
	[Amount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Balance_Amount] [decimal](16, 2) NOT NULL,
	[Balance_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[EffectiveBalance_Amount] [decimal](16, 2) NOT NULL,
	[EffectiveBalance_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[ExternalTaxImpositionType] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[TaxTypeId] [bigint] NULL,
	[ExternalJurisdictionLevelId] [bigint] NULL,
	[ReceivableTaxDetailId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[TaxBasisType] [nvarchar](5) COLLATE Latin1_General_CI_AS NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ReceivableTaxImpositions]  WITH CHECK ADD  CONSTRAINT [EReceivableTaxDetail_ReceivableTaxImpositions] FOREIGN KEY([ReceivableTaxDetailId])
REFERENCES [dbo].[ReceivableTaxDetails] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[ReceivableTaxImpositions] CHECK CONSTRAINT [EReceivableTaxDetail_ReceivableTaxImpositions]
GO
ALTER TABLE [dbo].[ReceivableTaxImpositions]  WITH CHECK ADD  CONSTRAINT [EReceivableTaxImposition_ExternalJurisdictionLevel] FOREIGN KEY([ExternalJurisdictionLevelId])
REFERENCES [dbo].[TaxAuthorityConfigs] ([Id])
GO
ALTER TABLE [dbo].[ReceivableTaxImpositions] CHECK CONSTRAINT [EReceivableTaxImposition_ExternalJurisdictionLevel]
GO
ALTER TABLE [dbo].[ReceivableTaxImpositions]  WITH CHECK ADD  CONSTRAINT [EReceivableTaxImposition_TaxType] FOREIGN KEY([TaxTypeId])
REFERENCES [dbo].[TaxTypes] ([Id])
GO
ALTER TABLE [dbo].[ReceivableTaxImpositions] CHECK CONSTRAINT [EReceivableTaxImposition_TaxType]
GO
ALTER TABLE [dbo].[ReceivableTaxImpositions]  WITH NOCHECK ADD  CONSTRAINT [CK_ReceivableTaxImpositions_Balance] CHECK  (([Balance_Amount]>=(0) AND [Balance_Amount]<=[Amount_Amount] OR [Balance_Amount]<=(0) AND [Balance_Amount]>=[Amount_Amount]))
GO
ALTER TABLE [dbo].[ReceivableTaxImpositions] CHECK CONSTRAINT [CK_ReceivableTaxImpositions_Balance]
GO
ALTER TABLE [dbo].[ReceivableTaxImpositions]  WITH NOCHECK ADD  CONSTRAINT [CK_ReceivableTaxImpositions_EffectiveBalance] CHECK  (([EffectiveBalance_Amount]>=(0) AND [EffectiveBalance_Amount]<=[Amount_Amount] OR [EffectiveBalance_Amount]<=(0) AND [EffectiveBalance_Amount]>=[Amount_Amount]))
GO
ALTER TABLE [dbo].[ReceivableTaxImpositions] CHECK CONSTRAINT [CK_ReceivableTaxImpositions_EffectiveBalance]
GO
