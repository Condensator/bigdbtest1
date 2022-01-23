SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CollateralTrackings](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[EntityType] [nvarchar](11) COLLATE Latin1_General_CI_AS NULL,
	[EntityId] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[Title] [nvarchar](6) COLLATE Latin1_General_CI_AS NULL,
	[CompletingTitleWork] [nvarchar](13) COLLATE Latin1_General_CI_AS NULL,
	[ContactName] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[ContactPhone] [nvarchar](15) COLLATE Latin1_General_CI_AS NULL,
	[CollateralStatus] [nvarchar](13) COLLATE Latin1_General_CI_AS NULL,
	[CollateralTitleReleaseStatus] [nvarchar](29) COLLATE Latin1_General_CI_AS NULL,
	[CollateralPosition] [nvarchar](19) COLLATE Latin1_General_CI_AS NULL,
	[IsCollateralConfirmation] [bit] NOT NULL,
	[CollateralType] [nvarchar](26) COLLATE Latin1_General_CI_AS NULL,
	[IsCrossCollateralized] [bit] NOT NULL,
	[RegistrationRenewalDate] [date] NULL,
	[FAAFilingNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[InternationalRegistryFileNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[PlateTailNumberVessel] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[ReleasedTo] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[AssignedTo] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[ThirdPartyTitleAgency] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[AssetId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CollateralTrackings]  WITH CHECK ADD  CONSTRAINT [ECollateralTracking_Asset] FOREIGN KEY([AssetId])
REFERENCES [dbo].[Assets] ([Id])
GO
ALTER TABLE [dbo].[CollateralTrackings] CHECK CONSTRAINT [ECollateralTracking_Asset]
GO
