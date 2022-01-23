CREATE TYPE [dbo].[PartyAddressDAMVRReportDetail] AS TABLE(
	[DistrictName] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[DistrictNameLatin] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[MunicipalityName] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[MunicipalityNameLatin] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[SettlementCode] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[SettlementName] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[SettlementNameLatin] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[LocationCode] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[LocationName] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[LocationNameLatin] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[BuildingNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[Entrance] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[Floor] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[Apartment] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
