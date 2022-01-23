SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CountryCurrencyRelationships](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsDefault] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[MandatoryAccountNumberField] [nvarchar](13) COLLATE Latin1_General_CI_AS NOT NULL,
	[RoutingNumberLength] [int] NOT NULL,
	[TransitCodeLength] [int] NOT NULL,
	[CountryId] [bigint] NOT NULL,
	[CurrencyId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CountryCurrencyRelationships]  WITH CHECK ADD  CONSTRAINT [ECountryCurrencyRelationship_Country] FOREIGN KEY([CountryId])
REFERENCES [dbo].[Countries] ([Id])
GO
ALTER TABLE [dbo].[CountryCurrencyRelationships] CHECK CONSTRAINT [ECountryCurrencyRelationship_Country]
GO
ALTER TABLE [dbo].[CountryCurrencyRelationships]  WITH CHECK ADD  CONSTRAINT [ECountryCurrencyRelationship_Currency] FOREIGN KEY([CurrencyId])
REFERENCES [dbo].[Currencies] ([Id])
GO
ALTER TABLE [dbo].[CountryCurrencyRelationships] CHECK CONSTRAINT [ECountryCurrencyRelationship_Currency]
GO
