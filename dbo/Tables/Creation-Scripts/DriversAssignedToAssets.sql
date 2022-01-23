SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DriversAssignedToAssets](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Assign] [bit] NOT NULL,
	[AssignedDate] [date] NULL,
	[UnassignedDate] [date] NULL,
	[IsPrimary] [bit] NOT NULL,
	[AssetId] [bigint] NULL,
	[DriverId] [bigint] NOT NULL,
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
ALTER TABLE [dbo].[DriversAssignedToAssets]  WITH CHECK ADD  CONSTRAINT [EDriver_DriversAssignedToAssets] FOREIGN KEY([DriverId])
REFERENCES [dbo].[Drivers] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[DriversAssignedToAssets] CHECK CONSTRAINT [EDriver_DriversAssignedToAssets]
GO
ALTER TABLE [dbo].[DriversAssignedToAssets]  WITH CHECK ADD  CONSTRAINT [EDriversAssignedToAsset_Asset] FOREIGN KEY([AssetId])
REFERENCES [dbo].[Assets] ([Id])
GO
ALTER TABLE [dbo].[DriversAssignedToAssets] CHECK CONSTRAINT [EDriversAssignedToAsset_Asset]
GO
