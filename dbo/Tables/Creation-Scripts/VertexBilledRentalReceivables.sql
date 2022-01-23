SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[VertexBilledRentalReceivables](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[RevenueBilledToDate_Amount] [decimal](16, 2) NOT NULL,
	[RevenueBilledToDate_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[CumulativeAmount_Amount] [decimal](16, 2) NOT NULL,
	[CumulativeAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ContractId] [bigint] NOT NULL,
	[ReceivableDetailId] [bigint] NULL,
	[AssetId] [bigint] NULL,
	[StateId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[AssetSKUId] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[VertexBilledRentalReceivables]  WITH CHECK ADD  CONSTRAINT [EVertexBilledRentalReceivable_Asset] FOREIGN KEY([AssetId])
REFERENCES [dbo].[Assets] ([Id])
GO
ALTER TABLE [dbo].[VertexBilledRentalReceivables] CHECK CONSTRAINT [EVertexBilledRentalReceivable_Asset]
GO
ALTER TABLE [dbo].[VertexBilledRentalReceivables]  WITH CHECK ADD  CONSTRAINT [EVertexBilledRentalReceivable_AssetSKU] FOREIGN KEY([AssetSKUId])
REFERENCES [dbo].[AssetSKUs] ([Id])
GO
ALTER TABLE [dbo].[VertexBilledRentalReceivables] CHECK CONSTRAINT [EVertexBilledRentalReceivable_AssetSKU]
GO
ALTER TABLE [dbo].[VertexBilledRentalReceivables]  WITH CHECK ADD  CONSTRAINT [EVertexBilledRentalReceivable_Contract] FOREIGN KEY([ContractId])
REFERENCES [dbo].[Contracts] ([Id])
GO
ALTER TABLE [dbo].[VertexBilledRentalReceivables] CHECK CONSTRAINT [EVertexBilledRentalReceivable_Contract]
GO
ALTER TABLE [dbo].[VertexBilledRentalReceivables]  WITH CHECK ADD  CONSTRAINT [EVertexBilledRentalReceivable_ReceivableDetail] FOREIGN KEY([ReceivableDetailId])
REFERENCES [dbo].[ReceivableDetails] ([Id])
GO
ALTER TABLE [dbo].[VertexBilledRentalReceivables] CHECK CONSTRAINT [EVertexBilledRentalReceivable_ReceivableDetail]
GO
ALTER TABLE [dbo].[VertexBilledRentalReceivables]  WITH CHECK ADD  CONSTRAINT [EVertexBilledRentalReceivable_State] FOREIGN KEY([StateId])
REFERENCES [dbo].[States] ([Id])
GO
ALTER TABLE [dbo].[VertexBilledRentalReceivables] CHECK CONSTRAINT [EVertexBilledRentalReceivable_State]
GO
