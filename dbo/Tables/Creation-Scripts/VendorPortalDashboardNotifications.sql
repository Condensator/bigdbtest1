SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[VendorPortalDashboardNotifications](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[SourceType] [nvarchar](19) COLLATE Latin1_General_CI_AS NOT NULL,
	[Status] [nvarchar](9) COLLATE Latin1_General_CI_AS NOT NULL,
	[Description] [nvarchar](4000) COLLATE Latin1_General_CI_AS NULL,
	[EntitySummary] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[VendorId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[VendorPortalDashboardNotifications]  WITH CHECK ADD  CONSTRAINT [EVendorPortalDashboardNotification_Vendor] FOREIGN KEY([VendorId])
REFERENCES [dbo].[Vendors] ([Id])
GO
ALTER TABLE [dbo].[VendorPortalDashboardNotifications] CHECK CONSTRAINT [EVendorPortalDashboardNotification_Vendor]
GO
