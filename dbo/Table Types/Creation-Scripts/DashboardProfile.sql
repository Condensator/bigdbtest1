CREATE TYPE [dbo].[DashboardProfile] AS TABLE(
	[Name] [nvarchar](50) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[Description] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[ActivationDate] [date] NOT NULL,
	[DeactivationDate] [date] NULL,
	[IsDisplayDetail] [bit] NOT NULL,
	[IsDisplayAttachment] [bit] NOT NULL,
	[IsDisplaySalesRepInfo] [bit] NOT NULL,
	[BannerImage_Source] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[BannerImage_Type] [nvarchar](5) COLLATE Latin1_General_CI_AS NULL,
	[BannerImage_Content] [varbinary](82) NULL,
	[IsDefault] [bit] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
