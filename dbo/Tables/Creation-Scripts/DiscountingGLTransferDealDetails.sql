SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DiscountingGLTransferDealDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[DiscountingGLTransferId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[GLSegmentChangeComment] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[ExistingFinanceId] [bigint] NOT NULL,
	[DiscountingId] [bigint] NOT NULL,
	[NewLegalEntityId] [bigint] NULL,
	[NewLineofBusinessId] [bigint] NULL,
	[NewCostCenterId] [bigint] NULL,
	[RemitToId] [bigint] NULL,
	[InstrumentTypeId] [bigint] NULL,
	[NewBranchId] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[DiscountingGLTransferDealDetails]  WITH CHECK ADD  CONSTRAINT [EDiscountingGLTransfer_DiscountingGLTransferDealDetails] FOREIGN KEY([DiscountingGLTransferId])
REFERENCES [dbo].[DiscountingGLTransfers] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[DiscountingGLTransferDealDetails] CHECK CONSTRAINT [EDiscountingGLTransfer_DiscountingGLTransferDealDetails]
GO
ALTER TABLE [dbo].[DiscountingGLTransferDealDetails]  WITH CHECK ADD  CONSTRAINT [EDiscountingGLTransferDealDetail_Discounting] FOREIGN KEY([DiscountingId])
REFERENCES [dbo].[Discountings] ([Id])
GO
ALTER TABLE [dbo].[DiscountingGLTransferDealDetails] CHECK CONSTRAINT [EDiscountingGLTransferDealDetail_Discounting]
GO
ALTER TABLE [dbo].[DiscountingGLTransferDealDetails]  WITH CHECK ADD  CONSTRAINT [EDiscountingGLTransferDealDetail_InstrumentType] FOREIGN KEY([InstrumentTypeId])
REFERENCES [dbo].[InstrumentTypes] ([Id])
GO
ALTER TABLE [dbo].[DiscountingGLTransferDealDetails] CHECK CONSTRAINT [EDiscountingGLTransferDealDetail_InstrumentType]
GO
ALTER TABLE [dbo].[DiscountingGLTransferDealDetails]  WITH CHECK ADD  CONSTRAINT [EDiscountingGLTransferDealDetail_NewBranch] FOREIGN KEY([NewBranchId])
REFERENCES [dbo].[Branches] ([Id])
GO
ALTER TABLE [dbo].[DiscountingGLTransferDealDetails] CHECK CONSTRAINT [EDiscountingGLTransferDealDetail_NewBranch]
GO
ALTER TABLE [dbo].[DiscountingGLTransferDealDetails]  WITH CHECK ADD  CONSTRAINT [EDiscountingGLTransferDealDetail_NewCostCenter] FOREIGN KEY([NewCostCenterId])
REFERENCES [dbo].[CostCenterConfigs] ([Id])
GO
ALTER TABLE [dbo].[DiscountingGLTransferDealDetails] CHECK CONSTRAINT [EDiscountingGLTransferDealDetail_NewCostCenter]
GO
ALTER TABLE [dbo].[DiscountingGLTransferDealDetails]  WITH CHECK ADD  CONSTRAINT [EDiscountingGLTransferDealDetail_NewLegalEntity] FOREIGN KEY([NewLegalEntityId])
REFERENCES [dbo].[LegalEntities] ([Id])
GO
ALTER TABLE [dbo].[DiscountingGLTransferDealDetails] CHECK CONSTRAINT [EDiscountingGLTransferDealDetail_NewLegalEntity]
GO
ALTER TABLE [dbo].[DiscountingGLTransferDealDetails]  WITH CHECK ADD  CONSTRAINT [EDiscountingGLTransferDealDetail_NewLineofBusiness] FOREIGN KEY([NewLineofBusinessId])
REFERENCES [dbo].[LineofBusinesses] ([Id])
GO
ALTER TABLE [dbo].[DiscountingGLTransferDealDetails] CHECK CONSTRAINT [EDiscountingGLTransferDealDetail_NewLineofBusiness]
GO
ALTER TABLE [dbo].[DiscountingGLTransferDealDetails]  WITH CHECK ADD  CONSTRAINT [EDiscountingGLTransferDealDetail_RemitTo] FOREIGN KEY([RemitToId])
REFERENCES [dbo].[RemitToes] ([Id])
GO
ALTER TABLE [dbo].[DiscountingGLTransferDealDetails] CHECK CONSTRAINT [EDiscountingGLTransferDealDetail_RemitTo]
GO
