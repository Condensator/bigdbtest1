SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[GLTransferDealDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[HoldingStatusComment] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[IncomeBalance_Amount] [decimal](16, 2) NULL,
	[IncomeBalance_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[GLSegmentChangeComment] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[NewAcquisitionId] [nvarchar](12) COLLATE Latin1_General_CI_AS NULL,
	[NewBQNBQ] [nvarchar](16) COLLATE Latin1_General_CI_AS NULL,
	[NewSOP] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[ExistingFinanceId] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ContractId] [bigint] NOT NULL,
	[NewLegalEntityId] [bigint] NULL,
	[BlendedItemCodeId] [bigint] NULL,
	[NewLineofBusinessId] [bigint] NULL,
	[RemitToId] [bigint] NULL,
	[ValuationAllowanceBlendedItemId] [bigint] NULL,
	[InstrumentTypeId] [bigint] NULL,
	[GLTransferId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[BookDepreciationTemplateId] [bigint] NULL,
	[NewCostCenterId] [bigint] NULL,
	[NewBranchId] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[GLTransferDealDetails]  WITH CHECK ADD  CONSTRAINT [EGLTransfer_GLTransferDealDetails] FOREIGN KEY([GLTransferId])
REFERENCES [dbo].[GLTransfers] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[GLTransferDealDetails] CHECK CONSTRAINT [EGLTransfer_GLTransferDealDetails]
GO
ALTER TABLE [dbo].[GLTransferDealDetails]  WITH CHECK ADD  CONSTRAINT [EGLTransferDealDetail_BlendedItemCode] FOREIGN KEY([BlendedItemCodeId])
REFERENCES [dbo].[BlendedItemCodes] ([Id])
GO
ALTER TABLE [dbo].[GLTransferDealDetails] CHECK CONSTRAINT [EGLTransferDealDetail_BlendedItemCode]
GO
ALTER TABLE [dbo].[GLTransferDealDetails]  WITH CHECK ADD  CONSTRAINT [EGLTransferDealDetail_BookDepreciationTemplate] FOREIGN KEY([BookDepreciationTemplateId])
REFERENCES [dbo].[BookDepreciationTemplates] ([Id])
GO
ALTER TABLE [dbo].[GLTransferDealDetails] CHECK CONSTRAINT [EGLTransferDealDetail_BookDepreciationTemplate]
GO
ALTER TABLE [dbo].[GLTransferDealDetails]  WITH CHECK ADD  CONSTRAINT [EGLTransferDealDetail_Contract] FOREIGN KEY([ContractId])
REFERENCES [dbo].[Contracts] ([Id])
GO
ALTER TABLE [dbo].[GLTransferDealDetails] CHECK CONSTRAINT [EGLTransferDealDetail_Contract]
GO
ALTER TABLE [dbo].[GLTransferDealDetails]  WITH CHECK ADD  CONSTRAINT [EGLTransferDealDetail_InstrumentType] FOREIGN KEY([InstrumentTypeId])
REFERENCES [dbo].[InstrumentTypes] ([Id])
GO
ALTER TABLE [dbo].[GLTransferDealDetails] CHECK CONSTRAINT [EGLTransferDealDetail_InstrumentType]
GO
ALTER TABLE [dbo].[GLTransferDealDetails]  WITH CHECK ADD  CONSTRAINT [EGLTransferDealDetail_NewBranch] FOREIGN KEY([NewBranchId])
REFERENCES [dbo].[Branches] ([Id])
GO
ALTER TABLE [dbo].[GLTransferDealDetails] CHECK CONSTRAINT [EGLTransferDealDetail_NewBranch]
GO
ALTER TABLE [dbo].[GLTransferDealDetails]  WITH CHECK ADD  CONSTRAINT [EGLTransferDealDetail_NewCostCenter] FOREIGN KEY([NewCostCenterId])
REFERENCES [dbo].[CostCenterConfigs] ([Id])
GO
ALTER TABLE [dbo].[GLTransferDealDetails] CHECK CONSTRAINT [EGLTransferDealDetail_NewCostCenter]
GO
ALTER TABLE [dbo].[GLTransferDealDetails]  WITH CHECK ADD  CONSTRAINT [EGLTransferDealDetail_NewLegalEntity] FOREIGN KEY([NewLegalEntityId])
REFERENCES [dbo].[LegalEntities] ([Id])
GO
ALTER TABLE [dbo].[GLTransferDealDetails] CHECK CONSTRAINT [EGLTransferDealDetail_NewLegalEntity]
GO
ALTER TABLE [dbo].[GLTransferDealDetails]  WITH CHECK ADD  CONSTRAINT [EGLTransferDealDetail_NewLineofBusiness] FOREIGN KEY([NewLineofBusinessId])
REFERENCES [dbo].[LineofBusinesses] ([Id])
GO
ALTER TABLE [dbo].[GLTransferDealDetails] CHECK CONSTRAINT [EGLTransferDealDetail_NewLineofBusiness]
GO
ALTER TABLE [dbo].[GLTransferDealDetails]  WITH CHECK ADD  CONSTRAINT [EGLTransferDealDetail_RemitTo] FOREIGN KEY([RemitToId])
REFERENCES [dbo].[RemitToes] ([Id])
GO
ALTER TABLE [dbo].[GLTransferDealDetails] CHECK CONSTRAINT [EGLTransferDealDetail_RemitTo]
GO
ALTER TABLE [dbo].[GLTransferDealDetails]  WITH CHECK ADD  CONSTRAINT [EGLTransferDealDetail_ValuationAllowanceBlendedItem] FOREIGN KEY([ValuationAllowanceBlendedItemId])
REFERENCES [dbo].[BlendedItems] ([Id])
GO
ALTER TABLE [dbo].[GLTransferDealDetails] CHECK CONSTRAINT [EGLTransferDealDetail_ValuationAllowanceBlendedItem]
GO
