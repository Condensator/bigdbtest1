SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AssumptionAssets](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[AssetId] [bigint] NOT NULL,
	[BillToId] [bigint] NULL,
	[LocationId] [bigint] NULL,
	[AssumptionId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[UpdateDriverAssignment] [bit] NOT NULL,
	[NewDriverId] [bigint] NULL,
	[OriginalLocationId] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[AssumptionAssets]  WITH CHECK ADD  CONSTRAINT [EAssumption_AssumptionAssets] FOREIGN KEY([AssumptionId])
REFERENCES [dbo].[Assumptions] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[AssumptionAssets] CHECK CONSTRAINT [EAssumption_AssumptionAssets]
GO
ALTER TABLE [dbo].[AssumptionAssets]  WITH CHECK ADD  CONSTRAINT [EAssumptionAssets_Asset] FOREIGN KEY([AssetId])
REFERENCES [dbo].[Assets] ([Id])
GO
ALTER TABLE [dbo].[AssumptionAssets] CHECK CONSTRAINT [EAssumptionAssets_Asset]
GO
ALTER TABLE [dbo].[AssumptionAssets]  WITH CHECK ADD  CONSTRAINT [EAssumptionAssets_BillTo] FOREIGN KEY([BillToId])
REFERENCES [dbo].[BillToes] ([Id])
GO
ALTER TABLE [dbo].[AssumptionAssets] CHECK CONSTRAINT [EAssumptionAssets_BillTo]
GO
ALTER TABLE [dbo].[AssumptionAssets]  WITH CHECK ADD  CONSTRAINT [EAssumptionAssets_Location] FOREIGN KEY([LocationId])
REFERENCES [dbo].[Locations] ([Id])
GO
ALTER TABLE [dbo].[AssumptionAssets] CHECK CONSTRAINT [EAssumptionAssets_Location]
GO
ALTER TABLE [dbo].[AssumptionAssets]  WITH CHECK ADD  CONSTRAINT [EAssumptionAssets_NewDriver] FOREIGN KEY([NewDriverId])
REFERENCES [dbo].[Drivers] ([Id])
GO
ALTER TABLE [dbo].[AssumptionAssets] CHECK CONSTRAINT [EAssumptionAssets_NewDriver]
GO
ALTER TABLE [dbo].[AssumptionAssets]  WITH CHECK ADD  CONSTRAINT [EAssumptionAssets_OriginalLocation] FOREIGN KEY([OriginalLocationId])
REFERENCES [dbo].[Locations] ([Id])
GO
ALTER TABLE [dbo].[AssumptionAssets] CHECK CONSTRAINT [EAssumptionAssets_OriginalLocation]
GO
