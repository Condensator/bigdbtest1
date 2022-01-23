SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PartyAddressDAMVRReportNationalityDetails](
	[NationalityCode] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[NationalityName] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[NationalityNameLatin] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[PartyId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[PartyAddressDAMVRReportNationalityDetails]  WITH CHECK ADD  CONSTRAINT [EParty_PartyAddressDAMVRReportNationalityDetails] FOREIGN KEY([PartyId])
REFERENCES [dbo].[Parties] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[PartyAddressDAMVRReportNationalityDetails] CHECK CONSTRAINT [EParty_PartyAddressDAMVRReportNationalityDetails]
GO
