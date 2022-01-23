SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[MobileAppConfigDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Version] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[IsSupported] [bit] NOT NULL,
	[PrimaryLogo_Source] [nvarchar](250) COLLATE Latin1_General_CI_AS NOT NULL,
	[PrimaryLogo_Type] [nvarchar](5) COLLATE Latin1_General_CI_AS NOT NULL,
	[PrimaryLogo_Content] [varbinary](82) NOT NULL,
	[SecondaryLogo_Source] [nvarchar](250) COLLATE Latin1_General_CI_AS NOT NULL,
	[SecondaryLogo_Type] [nvarchar](5) COLLATE Latin1_General_CI_AS NOT NULL,
	[SecondaryLogo_Content] [varbinary](82) NOT NULL,
	[DashboardFormName] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[MobileAppConfigId] [bigint] NOT NULL,
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
ALTER TABLE [dbo].[MobileAppConfigDetails]  WITH CHECK ADD  CONSTRAINT [EMobileAppConfig_MobileAppConfigDetails] FOREIGN KEY([MobileAppConfigId])
REFERENCES [dbo].[MobileAppConfigs] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[MobileAppConfigDetails] CHECK CONSTRAINT [EMobileAppConfig_MobileAppConfigDetails]
GO
