SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Locations](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Code] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[Name] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[AddressLine1] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[AddressLine2] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[Division] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[City] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[PostalCode] [nvarchar](12) COLLATE Latin1_General_CI_AS NULL,
	[Description] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[TaxAreaVerifiedTillDate] [date] NULL,
	[IsActive] [bit] NOT NULL,
	[TaxAreaId] [bigint] NULL,
	[ApprovalStatus] [nvarchar](9) COLLATE Latin1_General_CI_AS NOT NULL,
	[IncludedPostalCodeInLocationLookup] [bit] NOT NULL,
	[TaxBasisType] [nvarchar](5) COLLATE Latin1_General_CI_AS NULL,
	[UpfrontTaxMode] [nvarchar](6) COLLATE Latin1_General_CI_AS NULL,
	[CountryTaxExemptionRate] [decimal](10, 6) NULL,
	[StateTaxExemptionRate] [decimal](10, 6) NULL,
	[DivisionTaxExemptionRate] [decimal](10, 6) NULL,
	[CityTaxExemptionRate] [decimal](10, 6) NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[CustomerId] [bigint] NULL,
	[StateId] [bigint] NOT NULL,
	[JurisdictionId] [bigint] NULL,
	[ContactPersonId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[AddressLine3] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[Neighborhood] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[SubdivisionOrMunicipality] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[TaxExemptRuleId] [bigint] NOT NULL,
	[JurisdictionDetailId] [bigint] NULL,
	[PortfolioId] [bigint] NOT NULL,
	[VendorId] [bigint] NULL,
	[Latitude] [decimal](11, 8) NULL,
	[Longitude] [decimal](11, 8) NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[Locations]  WITH CHECK ADD  CONSTRAINT [ELocation_ContactPerson] FOREIGN KEY([ContactPersonId])
REFERENCES [dbo].[PartyContacts] ([Id])
GO
ALTER TABLE [dbo].[Locations] CHECK CONSTRAINT [ELocation_ContactPerson]
GO
ALTER TABLE [dbo].[Locations]  WITH CHECK ADD  CONSTRAINT [ELocation_Customer] FOREIGN KEY([CustomerId])
REFERENCES [dbo].[Customers] ([Id])
GO
ALTER TABLE [dbo].[Locations] CHECK CONSTRAINT [ELocation_Customer]
GO
ALTER TABLE [dbo].[Locations]  WITH CHECK ADD  CONSTRAINT [ELocation_Jurisdiction] FOREIGN KEY([JurisdictionId])
REFERENCES [dbo].[Jurisdictions] ([Id])
GO
ALTER TABLE [dbo].[Locations] CHECK CONSTRAINT [ELocation_Jurisdiction]
GO
ALTER TABLE [dbo].[Locations]  WITH CHECK ADD  CONSTRAINT [ELocation_JurisdictionDetail] FOREIGN KEY([JurisdictionDetailId])
REFERENCES [dbo].[JurisdictionDetails] ([Id])
GO
ALTER TABLE [dbo].[Locations] CHECK CONSTRAINT [ELocation_JurisdictionDetail]
GO
ALTER TABLE [dbo].[Locations]  WITH CHECK ADD  CONSTRAINT [ELocation_Portfolio] FOREIGN KEY([PortfolioId])
REFERENCES [dbo].[Portfolios] ([Id])
GO
ALTER TABLE [dbo].[Locations] CHECK CONSTRAINT [ELocation_Portfolio]
GO
ALTER TABLE [dbo].[Locations]  WITH CHECK ADD  CONSTRAINT [ELocation_State] FOREIGN KEY([StateId])
REFERENCES [dbo].[States] ([Id])
GO
ALTER TABLE [dbo].[Locations] CHECK CONSTRAINT [ELocation_State]
GO
ALTER TABLE [dbo].[Locations]  WITH CHECK ADD  CONSTRAINT [ELocation_TaxExemptRule] FOREIGN KEY([TaxExemptRuleId])
REFERENCES [dbo].[TaxExemptRules] ([Id])
GO
ALTER TABLE [dbo].[Locations] CHECK CONSTRAINT [ELocation_TaxExemptRule]
GO
ALTER TABLE [dbo].[Locations]  WITH CHECK ADD  CONSTRAINT [ELocation_Vendor] FOREIGN KEY([VendorId])
REFERENCES [dbo].[Vendors] ([Id])
GO
ALTER TABLE [dbo].[Locations] CHECK CONSTRAINT [ELocation_Vendor]
GO
