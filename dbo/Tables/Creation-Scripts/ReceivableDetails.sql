SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ReceivableDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Amount_Amount] [decimal](16, 2) NOT NULL,
	[Amount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Balance_Amount] [decimal](16, 2) NOT NULL,
	[Balance_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[EffectiveBalance_Amount] [decimal](16, 2) NOT NULL,
	[EffectiveBalance_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[EffectiveBookBalance_Amount] [decimal](16, 2) NULL,
	[EffectiveBookBalance_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[BilledStatus] [nvarchar](11) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsTaxAssessed] [bit] NOT NULL,
	[StopInvoicing] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[AssetId] [bigint] NULL,
	[BillToId] [bigint] NOT NULL,
	[AdjustmentBasisReceivableDetailId] [bigint] NULL,
	[ReceivableId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[AssetComponentType] [nvarchar](7) COLLATE Latin1_General_CI_AS NULL,
	[LeaseComponentAmount_Amount] [decimal](16, 2) NOT NULL,
	[NonLeaseComponentAmount_Amount] [decimal](16, 2) NOT NULL,
	[LeaseComponentBalance_Amount] [decimal](16, 2) NOT NULL,
	[NonLeaseComponentBalance_Amount] [decimal](16, 2) NOT NULL,
	[LeaseComponentAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[NonLeaseComponentAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[LeaseComponentBalance_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[NonLeaseComponentBalance_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[PreCapitalizationRent_Amount] [decimal](16, 2) NOT NULL,
	[PreCapitalizationRent_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ReceivableDetails]  WITH NOCHECK ADD  CONSTRAINT [EReceivable_ReceivableDetails] FOREIGN KEY([ReceivableId])
REFERENCES [dbo].[Receivables] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[ReceivableDetails] CHECK CONSTRAINT [EReceivable_ReceivableDetails]
GO
ALTER TABLE [dbo].[ReceivableDetails]  WITH NOCHECK ADD  CONSTRAINT [EReceivableDetail_AdjustmentBasisReceivableDetail] FOREIGN KEY([AdjustmentBasisReceivableDetailId])
REFERENCES [dbo].[ReceivableDetails] ([Id])
GO
ALTER TABLE [dbo].[ReceivableDetails] NOCHECK CONSTRAINT [EReceivableDetail_AdjustmentBasisReceivableDetail]
GO
ALTER TABLE [dbo].[ReceivableDetails]  WITH CHECK ADD  CONSTRAINT [EReceivableDetail_Asset] FOREIGN KEY([AssetId])
REFERENCES [dbo].[Assets] ([Id])
GO
ALTER TABLE [dbo].[ReceivableDetails] CHECK CONSTRAINT [EReceivableDetail_Asset]
GO
ALTER TABLE [dbo].[ReceivableDetails]  WITH CHECK ADD  CONSTRAINT [EReceivableDetail_BillTo] FOREIGN KEY([BillToId])
REFERENCES [dbo].[BillToes] ([Id])
GO
ALTER TABLE [dbo].[ReceivableDetails] CHECK CONSTRAINT [EReceivableDetail_BillTo]
GO
