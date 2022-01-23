SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[VendorLocationHistories](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[CreatedDate] [date] NULL,
	[IsActive] [bit] NOT NULL,
	[LocationId] [bigint] NULL,
	[PartyAddressId] [bigint] NULL,
	[VendorId] [bigint] NOT NULL,
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
ALTER TABLE [dbo].[VendorLocationHistories]  WITH CHECK ADD  CONSTRAINT [EVendor_VendorLocationHistories] FOREIGN KEY([VendorId])
REFERENCES [dbo].[Vendors] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[VendorLocationHistories] CHECK CONSTRAINT [EVendor_VendorLocationHistories]
GO
ALTER TABLE [dbo].[VendorLocationHistories]  WITH CHECK ADD  CONSTRAINT [EVendorLocationHistory_Location] FOREIGN KEY([LocationId])
REFERENCES [dbo].[Locations] ([Id])
GO
ALTER TABLE [dbo].[VendorLocationHistories] CHECK CONSTRAINT [EVendorLocationHistory_Location]
GO
ALTER TABLE [dbo].[VendorLocationHistories]  WITH CHECK ADD  CONSTRAINT [EVendorLocationHistory_PartyAddress] FOREIGN KEY([PartyAddressId])
REFERENCES [dbo].[PartyAddresses] ([Id])
GO
ALTER TABLE [dbo].[VendorLocationHistories] CHECK CONSTRAINT [EVendorLocationHistory_PartyAddress]
GO
