SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ProposalEquipmentDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Number] [int] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[IsActive] [bit] NOT NULL,
	[Cost_Amount] [decimal](16, 2) NOT NULL,
	[Cost_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Quantity] [bigint] NOT NULL,
	[TotalCost_Amount] [decimal](16, 2) NOT NULL,
	[TotalCost_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[RentFactor] [decimal](18, 8) NOT NULL,
	[Rent_Amount] [decimal](16, 2) NOT NULL,
	[Rent_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[InterestRate] [decimal](10, 6) NOT NULL,
	[ProposedResidualFactor] [decimal](18, 8) NOT NULL,
	[ProposedResidual_Amount] [decimal](16, 2) NOT NULL,
	[ProposedResidual_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[GuaranteedResidualFactor] [decimal](18, 8) NOT NULL,
	[GuaranteedResidual_Amount] [decimal](16, 2) NOT NULL,
	[GuaranteedResidual_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Description] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[PricingGroupId] [bigint] NOT NULL,
	[AssetTypeId] [bigint] NULL,
	[LocationId] [bigint] NULL,
	[VendorId] [bigint] NULL,
	[ProposalExhibitId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[InterimRentFactor] [decimal](18, 8) NOT NULL,
	[InterimRent_Amount] [decimal](16, 2) NOT NULL,
	[InterimRent_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ProposalEquipmentDetails]  WITH CHECK ADD  CONSTRAINT [EProposalEquipmentDetail_AssetType] FOREIGN KEY([AssetTypeId])
REFERENCES [dbo].[AssetTypes] ([Id])
GO
ALTER TABLE [dbo].[ProposalEquipmentDetails] CHECK CONSTRAINT [EProposalEquipmentDetail_AssetType]
GO
ALTER TABLE [dbo].[ProposalEquipmentDetails]  WITH CHECK ADD  CONSTRAINT [EProposalEquipmentDetail_Location] FOREIGN KEY([LocationId])
REFERENCES [dbo].[Locations] ([Id])
GO
ALTER TABLE [dbo].[ProposalEquipmentDetails] CHECK CONSTRAINT [EProposalEquipmentDetail_Location]
GO
ALTER TABLE [dbo].[ProposalEquipmentDetails]  WITH CHECK ADD  CONSTRAINT [EProposalEquipmentDetail_PricingGroup] FOREIGN KEY([PricingGroupId])
REFERENCES [dbo].[PricingGroups] ([Id])
GO
ALTER TABLE [dbo].[ProposalEquipmentDetails] CHECK CONSTRAINT [EProposalEquipmentDetail_PricingGroup]
GO
ALTER TABLE [dbo].[ProposalEquipmentDetails]  WITH CHECK ADD  CONSTRAINT [EProposalEquipmentDetail_Vendor] FOREIGN KEY([VendorId])
REFERENCES [dbo].[Vendors] ([Id])
GO
ALTER TABLE [dbo].[ProposalEquipmentDetails] CHECK CONSTRAINT [EProposalEquipmentDetail_Vendor]
GO
ALTER TABLE [dbo].[ProposalEquipmentDetails]  WITH CHECK ADD  CONSTRAINT [EProposalExhibit_ProposalEquipmentDetails] FOREIGN KEY([ProposalExhibitId])
REFERENCES [dbo].[ProposalExhibits] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[ProposalEquipmentDetails] CHECK CONSTRAINT [EProposalExhibit_ProposalEquipmentDetails]
GO
