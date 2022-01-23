SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LegalFormationTypeCountryConfigs](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[CountryId] [bigint] NOT NULL,
	[LegalFormationTypeConfigId] [bigint] NOT NULL,
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
ALTER TABLE [dbo].[LegalFormationTypeCountryConfigs]  WITH CHECK ADD  CONSTRAINT [ELegalFormationTypeCountryConfig_Country] FOREIGN KEY([CountryId])
REFERENCES [dbo].[Countries] ([Id])
GO
ALTER TABLE [dbo].[LegalFormationTypeCountryConfigs] CHECK CONSTRAINT [ELegalFormationTypeCountryConfig_Country]
GO
ALTER TABLE [dbo].[LegalFormationTypeCountryConfigs]  WITH CHECK ADD  CONSTRAINT [ELegalFormationTypeCountryConfig_LegalFormationTypeConfig] FOREIGN KEY([LegalFormationTypeConfigId])
REFERENCES [dbo].[LegalFormationTypeConfigs] ([Id])
GO
ALTER TABLE [dbo].[LegalFormationTypeCountryConfigs] CHECK CONSTRAINT [ELegalFormationTypeCountryConfig_LegalFormationTypeConfig]
GO
