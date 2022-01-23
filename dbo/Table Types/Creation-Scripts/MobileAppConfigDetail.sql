CREATE TYPE [dbo].[MobileAppConfigDetail] AS TABLE(
	[Version] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
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
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
