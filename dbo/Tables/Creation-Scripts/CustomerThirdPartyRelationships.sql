SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CustomerThirdPartyRelationships](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[RelationshipType] [nvarchar](30) COLLATE Latin1_General_CI_AS NOT NULL,
	[Description] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[ActivationDate] [date] NOT NULL,
	[DeactivationDate] [date] NULL,
	[IsNewRelation] [bit] NOT NULL,
	[IsNewAddress] [bit] NOT NULL,
	[IsFromAssumption] [bit] NOT NULL,
	[IsAssumptionApproved] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ThirdPartyId] [bigint] NULL,
	[ThirdPartyAddressId] [bigint] NULL,
	[ThirdPartyContactId] [bigint] NULL,
	[CustomerId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[LimitByDurationInMonths] [int] NULL,
	[LimitByPercentage] [decimal](5, 2) NULL,
	[LimitByAmount_Amount] [decimal](16, 2) NULL,
	[LimitByAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[Scope] [nvarchar](7) COLLATE Latin1_General_CI_AS NULL,
	[Coverage] [nvarchar](8) COLLATE Latin1_General_CI_AS NULL,
	[PersonalGuarantorCustomerOrContact] [nvarchar](8) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsNewContact] [bit] NOT NULL,
	[VendorId] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CustomerThirdPartyRelationships]  WITH CHECK ADD  CONSTRAINT [ECustomer_CustomerThirdPartyRelationships] FOREIGN KEY([CustomerId])
REFERENCES [dbo].[Customers] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CustomerThirdPartyRelationships] CHECK CONSTRAINT [ECustomer_CustomerThirdPartyRelationships]
GO
ALTER TABLE [dbo].[CustomerThirdPartyRelationships]  WITH CHECK ADD  CONSTRAINT [ECustomerThirdPartyRelationship_ThirdParty] FOREIGN KEY([ThirdPartyId])
REFERENCES [dbo].[Parties] ([Id])
GO
ALTER TABLE [dbo].[CustomerThirdPartyRelationships] CHECK CONSTRAINT [ECustomerThirdPartyRelationship_ThirdParty]
GO
ALTER TABLE [dbo].[CustomerThirdPartyRelationships]  WITH CHECK ADD  CONSTRAINT [ECustomerThirdPartyRelationship_ThirdPartyAddress] FOREIGN KEY([ThirdPartyAddressId])
REFERENCES [dbo].[PartyAddresses] ([Id])
GO
ALTER TABLE [dbo].[CustomerThirdPartyRelationships] CHECK CONSTRAINT [ECustomerThirdPartyRelationship_ThirdPartyAddress]
GO
ALTER TABLE [dbo].[CustomerThirdPartyRelationships]  WITH CHECK ADD  CONSTRAINT [ECustomerThirdPartyRelationship_ThirdPartyContact] FOREIGN KEY([ThirdPartyContactId])
REFERENCES [dbo].[PartyContacts] ([Id])
GO
ALTER TABLE [dbo].[CustomerThirdPartyRelationships] CHECK CONSTRAINT [ECustomerThirdPartyRelationship_ThirdPartyContact]
GO
ALTER TABLE [dbo].[CustomerThirdPartyRelationships]  WITH CHECK ADD  CONSTRAINT [ECustomerThirdPartyRelationShip_Vendor] FOREIGN KEY([VendorId])
REFERENCES [dbo].[Vendors] ([Id])
GO
ALTER TABLE [dbo].[CustomerThirdPartyRelationships] CHECK CONSTRAINT [ECustomerThirdPartyRelationShip_Vendor]
GO
