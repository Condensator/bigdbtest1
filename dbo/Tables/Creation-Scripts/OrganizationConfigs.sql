SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[OrganizationConfigs](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[FavIcon_Source] [nvarchar](250) COLLATE Latin1_General_CI_AS NOT NULL,
	[FavIcon_Type] [nvarchar](5) COLLATE Latin1_General_CI_AS NOT NULL,
	[FavIcon_Content] [varbinary](82) NOT NULL,
	[BrowserTitle] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[LoginBackground_Source] [nvarchar](250) COLLATE Latin1_General_CI_AS NOT NULL,
	[LoginBackground_Type] [nvarchar](5) COLLATE Latin1_General_CI_AS NOT NULL,
	[LoginBackground_Content] [varbinary](82) NOT NULL,
	[LoginLogo_Source] [nvarchar](250) COLLATE Latin1_General_CI_AS NOT NULL,
	[LoginLogo_Type] [nvarchar](5) COLLATE Latin1_General_CI_AS NOT NULL,
	[LoginLogo_Content] [varbinary](82) NOT NULL,
	[LoginTitle] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[TermsAndConditions] [nvarchar](max) COLLATE Latin1_General_CI_AS NOT NULL,
	[EmailContact] [nvarchar](70) COLLATE Latin1_General_CI_AS NOT NULL,
	[ContactMessage] [nvarchar](max) COLLATE Latin1_General_CI_AS NOT NULL,
	[MenuLogo_Source] [nvarchar](250) COLLATE Latin1_General_CI_AS NOT NULL,
	[MenuLogo_Type] [nvarchar](5) COLLATE Latin1_General_CI_AS NOT NULL,
	[MenuLogo_Content] [varbinary](82) NOT NULL,
	[FooterLogo_Source] [nvarchar](250) COLLATE Latin1_General_CI_AS NOT NULL,
	[FooterLogo_Type] [nvarchar](5) COLLATE Latin1_General_CI_AS NOT NULL,
	[FooterLogo_Content] [varbinary](82) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
