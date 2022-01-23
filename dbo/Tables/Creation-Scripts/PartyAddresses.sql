SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PartyAddresses](
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
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[StateId] [bigint] NULL,
	[HomeStateId] [bigint] NULL,
	[VendorId] [bigint] NULL,
	[PartyId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
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
	[IsCreateLocation] [bit] NOT NULL,
	[TaxAreaId] [bigint] NULL,
	[HomeAttentionTo] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[Settlement] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[HomeSettlement] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[IsCompanyHeadquartersPermanentAddress] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[PartyAddresses]  WITH CHECK ADD  CONSTRAINT [EParty_PartyAddresses] FOREIGN KEY([PartyId])
REFERENCES [dbo].[Parties] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[PartyAddresses] CHECK CONSTRAINT [EParty_PartyAddresses]
GO
ALTER TABLE [dbo].[PartyAddresses]  WITH CHECK ADD  CONSTRAINT [EPartyAddress_HomeState] FOREIGN KEY([HomeStateId])
REFERENCES [dbo].[States] ([Id])
GO
ALTER TABLE [dbo].[PartyAddresses] CHECK CONSTRAINT [EPartyAddress_HomeState]
GO
ALTER TABLE [dbo].[PartyAddresses]  WITH CHECK ADD  CONSTRAINT [EPartyAddress_State] FOREIGN KEY([StateId])
REFERENCES [dbo].[States] ([Id])
GO
ALTER TABLE [dbo].[PartyAddresses] CHECK CONSTRAINT [EPartyAddress_State]
GO
ALTER TABLE [dbo].[PartyAddresses]  WITH CHECK ADD  CONSTRAINT [EPartyAddress_Vendor] FOREIGN KEY([VendorId])
REFERENCES [dbo].[Parties] ([Id])
GO
ALTER TABLE [dbo].[PartyAddresses] CHECK CONSTRAINT [EPartyAddress_Vendor]
GO
