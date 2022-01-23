CREATE TYPE [dbo].[CurrencyCode] AS TABLE(
	[ISO] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[IsActive] [bit] NOT NULL,
	[Symbol] [nvarchar](10) COLLATE Latin1_General_CI_AS NULL,
	[CurrencyName] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[CurrencySubUnitName] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
