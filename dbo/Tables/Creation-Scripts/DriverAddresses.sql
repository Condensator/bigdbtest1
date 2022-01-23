SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DriverAddresses](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[UniqueIdentifier] [nvarchar](30) COLLATE Latin1_General_CI_AS NULL,
	[AddressLine1] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[AddressLine2] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[City] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[Division] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[PostalCode] [nvarchar](12) COLLATE Latin1_General_CI_AS NULL,
	[HomeAddressLine1] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[HomeAddressLine2] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[HomeCity] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[HomeDivision] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[HomePostalCode] [nvarchar](12) COLLATE Latin1_General_CI_AS NULL,
	[Description] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[IsMain] [bit] NOT NULL,
	[IsHeadquarter] [bit] NOT NULL,
	[AddressLine3] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[Neighborhood] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[SubdivisionOrMunicipality] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[HomeAddressLine3] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[HomeNeighborhood] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[HomeSubdivisionOrMunicipality] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[AttentionTo] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[SFDCAddressId] [nvarchar](30) COLLATE Latin1_General_CI_AS NULL,
	[IsForDocumentation] [bit] NOT NULL,
	[IsImportedAddress] [bit] NOT NULL,
	[StateId] [bigint] NULL,
	[HomeStateId] [bigint] NULL,
	[DriverId] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RowVersion] [timestamp] NOT NULL,
	[PartyAddressId] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[DriverAddresses]  WITH CHECK ADD  CONSTRAINT [EDriver_DriverAddresses] FOREIGN KEY([DriverId])
REFERENCES [dbo].[Drivers] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[DriverAddresses] CHECK CONSTRAINT [EDriver_DriverAddresses]
GO
ALTER TABLE [dbo].[DriverAddresses]  WITH CHECK ADD  CONSTRAINT [EDriverAddress_HomeState] FOREIGN KEY([HomeStateId])
REFERENCES [dbo].[States] ([Id])
GO
ALTER TABLE [dbo].[DriverAddresses] CHECK CONSTRAINT [EDriverAddress_HomeState]
GO
ALTER TABLE [dbo].[DriverAddresses]  WITH CHECK ADD  CONSTRAINT [EDriverAddress_PartyAddress] FOREIGN KEY([PartyAddressId])
REFERENCES [dbo].[PartyAddresses] ([Id])
GO
ALTER TABLE [dbo].[DriverAddresses] CHECK CONSTRAINT [EDriverAddress_PartyAddress]
GO
ALTER TABLE [dbo].[DriverAddresses]  WITH CHECK ADD  CONSTRAINT [EDriverAddress_State] FOREIGN KEY([StateId])
REFERENCES [dbo].[States] ([Id])
GO
ALTER TABLE [dbo].[DriverAddresses] CHECK CONSTRAINT [EDriverAddress_State]
GO
