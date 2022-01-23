SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CPUAssets](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[OriginalAssetCost_Amount] [decimal](16, 2) NULL,
	[OriginalAssetCost_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[BeginDate] [date] NOT NULL,
	[BaseUnits] [int] NULL,
	[BaseAmount_Amount] [decimal](16, 2) NOT NULL,
	[BaseAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[MaximumReading] [bigint] NULL,
	[IsActive] [bit] NOT NULL,
	[BillToId] [bigint] NOT NULL,
	[AssetId] [bigint] NOT NULL,
	[CPUScheduleId] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RowVersion] [timestamp] NOT NULL,
	[BaseReceivablesGeneratedTillDate] [date] NULL,
	[BaseDistributionBasisAmount_Amount] [decimal](16, 2) NOT NULL,
	[BaseDistributionBasisAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[OverageDistributionBasisAmount_Amount] [decimal](16, 2) NOT NULL,
	[OverageDistributionBasisAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[ContractId] [bigint] NULL,
	[IsServiceOnly] [bit] NOT NULL,
	[RemitToId] [bigint] NOT NULL,
	[IsCreatedFromBooking] [bit] NOT NULL,
	[PayoffDate] [date] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CPUAssets]  WITH CHECK ADD  CONSTRAINT [ECPUAsset_Asset] FOREIGN KEY([AssetId])
REFERENCES [dbo].[Assets] ([Id])
GO
ALTER TABLE [dbo].[CPUAssets] CHECK CONSTRAINT [ECPUAsset_Asset]
GO
ALTER TABLE [dbo].[CPUAssets]  WITH CHECK ADD  CONSTRAINT [ECPUAsset_BillTo] FOREIGN KEY([BillToId])
REFERENCES [dbo].[BillToes] ([Id])
GO
ALTER TABLE [dbo].[CPUAssets] CHECK CONSTRAINT [ECPUAsset_BillTo]
GO
ALTER TABLE [dbo].[CPUAssets]  WITH CHECK ADD  CONSTRAINT [ECPUAsset_Contract] FOREIGN KEY([ContractId])
REFERENCES [dbo].[Contracts] ([Id])
GO
ALTER TABLE [dbo].[CPUAssets] CHECK CONSTRAINT [ECPUAsset_Contract]
GO
ALTER TABLE [dbo].[CPUAssets]  WITH CHECK ADD  CONSTRAINT [ECPUAsset_RemitTo] FOREIGN KEY([RemitToId])
REFERENCES [dbo].[RemitToes] ([Id])
GO
ALTER TABLE [dbo].[CPUAssets] CHECK CONSTRAINT [ECPUAsset_RemitTo]
GO
ALTER TABLE [dbo].[CPUAssets]  WITH CHECK ADD  CONSTRAINT [ECPUSchedule_CPUAssets] FOREIGN KEY([CPUScheduleId])
REFERENCES [dbo].[CPUSchedules] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CPUAssets] CHECK CONSTRAINT [ECPUSchedule_CPUAssets]
GO
