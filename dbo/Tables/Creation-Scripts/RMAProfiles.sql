SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[RMAProfiles](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[TransactionNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[RMAStatus] [nvarchar](9) COLLATE Latin1_General_CI_AS NOT NULL,
	[NotifiedCustomer] [bit] NOT NULL,
	[NotifiedShippingCompany] [bit] NOT NULL,
	[NotifiedRefurbishmentCenter] [bit] NOT NULL,
	[Canadian] [bit] NOT NULL,
	[LastDateToBill] [date] NULL,
	[ShippingOption] [nvarchar](17) COLLATE Latin1_General_CI_AS NOT NULL,
	[ActualPickupDate] [date] NULL,
	[DeliveryDate] [date] NULL,
	[TrackingNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[InsuranceAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[InsuranceAmount_Amount] [decimal](16, 2) NOT NULL,
	[ShipFromPrimaryContact] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[ShipFromPhoneNumber1] [nvarchar](15) COLLATE Latin1_General_CI_AS NULL,
	[ShipFromMobilePhoneNumber1] [nvarchar](15) COLLATE Latin1_General_CI_AS NULL,
	[ShipFromEMailId1] [nvarchar](70) COLLATE Latin1_General_CI_AS NULL,
	[ShipFromAdditionalContact] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[ShipFromPhoneNumber2] [nvarchar](15) COLLATE Latin1_General_CI_AS NULL,
	[ShipFromMobilePhoneNumber2] [nvarchar](15) COLLATE Latin1_General_CI_AS NULL,
	[ShipFromEMailId2] [nvarchar](70) COLLATE Latin1_General_CI_AS NULL,
	[DockHours] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[CallFirst] [bit] NOT NULL,
	[ShipFromInside] [bit] NOT NULL,
	[ShipFromLiftgate] [bit] NOT NULL,
	[CityTruckRequired] [bit] NOT NULL,
	[ClimateControl] [bit] NOT NULL,
	[FloorCoveringNeeded] [bit] NOT NULL,
	[CertificateofInsuranceRequired] [bit] NOT NULL,
	[PackingNeeded] [bit] NOT NULL,
	[Wheels] [bit] NOT NULL,
	[Palletized] [bit] NOT NULL,
	[EstimatedWeight] [int] NULL,
	[EstimatedDimensions] [int] NULL,
	[DockHeight] [int] NULL,
	[FreightComment] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[InsuredValue_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[InsuredValue_Amount] [decimal](16, 2) NOT NULL,
	[DeInstallationRequired] [bit] NOT NULL,
	[Bandling] [bit] NOT NULL,
	[Licenses] [bit] NOT NULL,
	[WipeHardDrives] [bit] NOT NULL,
	[RestoreSoftware] [bit] NOT NULL,
	[PasswordsRequired] [bit] NOT NULL,
	[AuditRequired] [bit] NOT NULL,
	[EquipmentDispositionComment] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[ShipToPhoneNumber1] [nvarchar](15) COLLATE Latin1_General_CI_AS NULL,
	[ShipToMobilePhoneNumber1] [nvarchar](15) COLLATE Latin1_General_CI_AS NULL,
	[ShipToEMailId1] [nvarchar](70) COLLATE Latin1_General_CI_AS NULL,
	[ShipToPhoneNumber2] [nvarchar](15) COLLATE Latin1_General_CI_AS NULL,
	[ShipToMobilePhoneNumber2] [nvarchar](15) COLLATE Latin1_General_CI_AS NULL,
	[ShipToEMailId2] [nvarchar](70) COLLATE Latin1_General_CI_AS NULL,
	[ExpectedDeliveryDate] [date] NULL,
	[CustomerId] [bigint] NOT NULL,
	[SalesRepId] [bigint] NULL,
	[ProductManagerId] [bigint] NULL,
	[AuthorizedById] [bigint] NULL,
	[ShippingCompanyId] [bigint] NULL,
	[ShipFromLocationId] [bigint] NULL,
	[ShipToId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[AuditReceivedDate] [date] NULL,
	[ShipToInside] [bit] NOT NULL,
	[ShipToLiftgate] [bit] NOT NULL,
	[EstimatedPickupDate] [date] NULL,
	[ShipToLocationId] [bigint] NULL,
	[ShipFromAddressLine1] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[ShipFromAddressLine2] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[ShipFromCity] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[ShipFromStateId] [bigint] NULL,
	[ShipFromZip] [nvarchar](12) COLLATE Latin1_General_CI_AS NULL,
	[CurrencyId] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[UpdatedById] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[RMAProfiles]  WITH CHECK ADD  CONSTRAINT [ERMAProfile_AuthorizedBy] FOREIGN KEY([AuthorizedById])
REFERENCES [dbo].[Users] ([Id])
GO
ALTER TABLE [dbo].[RMAProfiles] CHECK CONSTRAINT [ERMAProfile_AuthorizedBy]
GO
ALTER TABLE [dbo].[RMAProfiles]  WITH CHECK ADD  CONSTRAINT [ERMAProfile_Currency] FOREIGN KEY([CurrencyId])
REFERENCES [dbo].[Currencies] ([Id])
GO
ALTER TABLE [dbo].[RMAProfiles] CHECK CONSTRAINT [ERMAProfile_Currency]
GO
ALTER TABLE [dbo].[RMAProfiles]  WITH CHECK ADD  CONSTRAINT [ERMAProfile_Customer] FOREIGN KEY([CustomerId])
REFERENCES [dbo].[Customers] ([Id])
GO
ALTER TABLE [dbo].[RMAProfiles] CHECK CONSTRAINT [ERMAProfile_Customer]
GO
ALTER TABLE [dbo].[RMAProfiles]  WITH CHECK ADD  CONSTRAINT [ERMAProfile_ProductManager] FOREIGN KEY([ProductManagerId])
REFERENCES [dbo].[Users] ([Id])
GO
ALTER TABLE [dbo].[RMAProfiles] CHECK CONSTRAINT [ERMAProfile_ProductManager]
GO
ALTER TABLE [dbo].[RMAProfiles]  WITH CHECK ADD  CONSTRAINT [ERMAProfile_SalesRep] FOREIGN KEY([SalesRepId])
REFERENCES [dbo].[Users] ([Id])
GO
ALTER TABLE [dbo].[RMAProfiles] CHECK CONSTRAINT [ERMAProfile_SalesRep]
GO
ALTER TABLE [dbo].[RMAProfiles]  WITH CHECK ADD  CONSTRAINT [ERMAProfile_ShipFromLocation] FOREIGN KEY([ShipFromLocationId])
REFERENCES [dbo].[Payoffs] ([Id])
GO
ALTER TABLE [dbo].[RMAProfiles] CHECK CONSTRAINT [ERMAProfile_ShipFromLocation]
GO
ALTER TABLE [dbo].[RMAProfiles]  WITH CHECK ADD  CONSTRAINT [ERMAProfile_ShipFromState] FOREIGN KEY([ShipFromStateId])
REFERENCES [dbo].[States] ([Id])
GO
ALTER TABLE [dbo].[RMAProfiles] CHECK CONSTRAINT [ERMAProfile_ShipFromState]
GO
ALTER TABLE [dbo].[RMAProfiles]  WITH CHECK ADD  CONSTRAINT [ERMAProfile_ShippingCompany] FOREIGN KEY([ShippingCompanyId])
REFERENCES [dbo].[Vendors] ([Id])
GO
ALTER TABLE [dbo].[RMAProfiles] CHECK CONSTRAINT [ERMAProfile_ShippingCompany]
GO
ALTER TABLE [dbo].[RMAProfiles]  WITH CHECK ADD  CONSTRAINT [ERMAProfile_ShipTo] FOREIGN KEY([ShipToId])
REFERENCES [dbo].[Vendors] ([Id])
GO
ALTER TABLE [dbo].[RMAProfiles] CHECK CONSTRAINT [ERMAProfile_ShipTo]
GO
ALTER TABLE [dbo].[RMAProfiles]  WITH CHECK ADD  CONSTRAINT [ERMAProfile_ShipToLocation] FOREIGN KEY([ShipToLocationId])
REFERENCES [dbo].[PartyAddresses] ([Id])
GO
ALTER TABLE [dbo].[RMAProfiles] CHECK CONSTRAINT [ERMAProfile_ShipToLocation]
GO
