SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ProposalShellAssets](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[EquipmentTypeName] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[ModalityName] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[Quantity] [int] NOT NULL,
	[ManufacturerName] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[EquipmentLocation] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[EquipmentDescription] [nvarchar](1000) COLLATE Latin1_General_CI_AS NULL,
	[ModelYear] [decimal](4, 0) NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ProposalId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[Model] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[SellingPrice_Amount] [decimal](16, 2) NULL,
	[SellingPrice_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ProposalShellAssets]  WITH CHECK ADD  CONSTRAINT [EProposal_ProposalShellAssets] FOREIGN KEY([ProposalId])
REFERENCES [dbo].[Proposals] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[ProposalShellAssets] CHECK CONSTRAINT [EProposal_ProposalShellAssets]
GO
