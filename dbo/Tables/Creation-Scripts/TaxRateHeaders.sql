SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TaxRateHeaders](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RowVersion] [timestamp] NOT NULL,
	[CityId] [bigint] NULL,
	[CountyId] [bigint] NULL,
	[CountryId] [bigint] NOT NULL,
	[StateId] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[TaxRateHeaders]  WITH CHECK ADD  CONSTRAINT [ETaxRateHeader_City] FOREIGN KEY([CityId])
REFERENCES [dbo].[Cities] ([Id])
GO
ALTER TABLE [dbo].[TaxRateHeaders] CHECK CONSTRAINT [ETaxRateHeader_City]
GO
ALTER TABLE [dbo].[TaxRateHeaders]  WITH CHECK ADD  CONSTRAINT [ETaxRateHeader_Country] FOREIGN KEY([CountryId])
REFERENCES [dbo].[Countries] ([Id])
GO
ALTER TABLE [dbo].[TaxRateHeaders] CHECK CONSTRAINT [ETaxRateHeader_Country]
GO
ALTER TABLE [dbo].[TaxRateHeaders]  WITH CHECK ADD  CONSTRAINT [ETaxRateHeader_County] FOREIGN KEY([CountyId])
REFERENCES [dbo].[Counties] ([Id])
GO
ALTER TABLE [dbo].[TaxRateHeaders] CHECK CONSTRAINT [ETaxRateHeader_County]
GO
ALTER TABLE [dbo].[TaxRateHeaders]  WITH CHECK ADD  CONSTRAINT [ETaxRateHeader_State] FOREIGN KEY([StateId])
REFERENCES [dbo].[States] ([Id])
GO
ALTER TABLE [dbo].[TaxRateHeaders] CHECK CONSTRAINT [ETaxRateHeader_State]
GO
