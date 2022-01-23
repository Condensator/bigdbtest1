CREATE TYPE [dbo].[Jurisdiction] AS TABLE(
	[GeoCode] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[IsActive] [bit] NOT NULL,
	[CityId] [bigint] NULL,
	[CountyId] [bigint] NULL,
	[StateId] [bigint] NULL,
	[CountryId] [bigint] NOT NULL,
	[TaxRateHeaderId] [bigint] NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
