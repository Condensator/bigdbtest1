SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PartyAddressDAMVRReportDetails](
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
	[RowVersion] [timestamp] NOT NULL,
 CONSTRAINT [PK_PartyAddressDAMVRReportDetails] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[PartyAddressDAMVRReportDetails]  WITH CHECK ADD  CONSTRAINT [EPartyAddress_PartyAddressDAMVRReportDetail] FOREIGN KEY([Id])
REFERENCES [dbo].[PartyAddresses] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[PartyAddressDAMVRReportDetails] CHECK CONSTRAINT [EPartyAddress_PartyAddressDAMVRReportDetail]
GO
