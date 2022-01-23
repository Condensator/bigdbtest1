SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ContractSalesTaxRemittanceResponsibilityHistories](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[ContractId] [bigint] NOT NULL,
	[AssetId] [bigint] NOT NULL,
	[EffectiveTillDate] [date] NULL,
	[SalesTaxRemittanceResponsibility] [nvarchar](8) COLLATE Latin1_General_CI_AS NOT NULL,
	[VendorRemitToId] [bigint] NULL,
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
ALTER TABLE [dbo].[ContractSalesTaxRemittanceResponsibilityHistories]  WITH CHECK ADD  CONSTRAINT [EContract_ContractSalesTaxRemittanceResponsibilityHistories] FOREIGN KEY([ContractId])
REFERENCES [dbo].[Contracts] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[ContractSalesTaxRemittanceResponsibilityHistories] CHECK CONSTRAINT [EContract_ContractSalesTaxRemittanceResponsibilityHistories]
GO
ALTER TABLE [dbo].[ContractSalesTaxRemittanceResponsibilityHistories]  WITH CHECK ADD  CONSTRAINT [EContractSalesTaxRemittanceResponsibilityHistory_Asset] FOREIGN KEY([AssetId])
REFERENCES [dbo].[Assets] ([Id])
GO
ALTER TABLE [dbo].[ContractSalesTaxRemittanceResponsibilityHistories] CHECK CONSTRAINT [EContractSalesTaxRemittanceResponsibilityHistory_Asset]
GO
ALTER TABLE [dbo].[ContractSalesTaxRemittanceResponsibilityHistories]  WITH CHECK ADD  CONSTRAINT [EContractSalesTaxRemittanceResponsibilityHistory_VendorRemitTo] FOREIGN KEY([VendorRemitToId])
REFERENCES [dbo].[RemitToes] ([Id])
GO
ALTER TABLE [dbo].[ContractSalesTaxRemittanceResponsibilityHistories] CHECK CONSTRAINT [EContractSalesTaxRemittanceResponsibilityHistory_VendorRemitTo]
GO
