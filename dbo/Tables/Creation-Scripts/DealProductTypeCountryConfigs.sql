SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DealProductTypeCountryConfigs](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[CountryId] [bigint] NOT NULL,
	[DealProductTypeId] [bigint] NOT NULL,
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
ALTER TABLE [dbo].[DealProductTypeCountryConfigs]  WITH CHECK ADD  CONSTRAINT [EDealProductTypeCountryConfig_Country] FOREIGN KEY([CountryId])
REFERENCES [dbo].[Countries] ([Id])
GO
ALTER TABLE [dbo].[DealProductTypeCountryConfigs] CHECK CONSTRAINT [EDealProductTypeCountryConfig_Country]
GO
ALTER TABLE [dbo].[DealProductTypeCountryConfigs]  WITH CHECK ADD  CONSTRAINT [EDealProductTypeCountryConfig_DealProductType] FOREIGN KEY([DealProductTypeId])
REFERENCES [dbo].[DealProductTypes] ([Id])
GO
ALTER TABLE [dbo].[DealProductTypeCountryConfigs] CHECK CONSTRAINT [EDealProductTypeCountryConfig_DealProductType]
GO
