SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Jurisdictions](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[GeoCode] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[CityId] [bigint] NULL,
	[CountyId] [bigint] NULL,
	[StateId] [bigint] NULL,
	[CountryId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[TaxRateHeaderId] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[Jurisdictions]  WITH CHECK ADD  CONSTRAINT [EJurisdiction_City] FOREIGN KEY([CityId])
REFERENCES [dbo].[Cities] ([Id])
GO
ALTER TABLE [dbo].[Jurisdictions] CHECK CONSTRAINT [EJurisdiction_City]
GO
ALTER TABLE [dbo].[Jurisdictions]  WITH CHECK ADD  CONSTRAINT [EJurisdiction_Country] FOREIGN KEY([CountryId])
REFERENCES [dbo].[Countries] ([Id])
GO
ALTER TABLE [dbo].[Jurisdictions] CHECK CONSTRAINT [EJurisdiction_Country]
GO
ALTER TABLE [dbo].[Jurisdictions]  WITH CHECK ADD  CONSTRAINT [EJurisdiction_County] FOREIGN KEY([CountyId])
REFERENCES [dbo].[Counties] ([Id])
GO
ALTER TABLE [dbo].[Jurisdictions] CHECK CONSTRAINT [EJurisdiction_County]
GO
ALTER TABLE [dbo].[Jurisdictions]  WITH CHECK ADD  CONSTRAINT [EJurisdiction_State] FOREIGN KEY([StateId])
REFERENCES [dbo].[States] ([Id])
GO
ALTER TABLE [dbo].[Jurisdictions] CHECK CONSTRAINT [EJurisdiction_State]
GO
ALTER TABLE [dbo].[Jurisdictions]  WITH CHECK ADD  CONSTRAINT [EJurisdiction_TaxRateHeader] FOREIGN KEY([TaxRateHeaderId])
REFERENCES [dbo].[TaxRateHeaders] ([Id])
GO
ALTER TABLE [dbo].[Jurisdictions] CHECK CONSTRAINT [EJurisdiction_TaxRateHeader]
GO
