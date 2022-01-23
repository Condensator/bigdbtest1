CREATE TYPE [dbo].[Logo] AS TABLE(
	[Name] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[EntityType] [nvarchar](6) COLLATE Latin1_General_CI_AS NOT NULL,
	[LogoImageFile_Source] [nvarchar](250) COLLATE Latin1_General_CI_AS NOT NULL,
	[LogoImageFile_Type] [nvarchar](5) COLLATE Latin1_General_CI_AS NOT NULL,
	[LogoImageFile_Content] [varbinary](82) NOT NULL,
	[Comment] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[PartyId] [bigint] NULL,
	[PortfolioId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
