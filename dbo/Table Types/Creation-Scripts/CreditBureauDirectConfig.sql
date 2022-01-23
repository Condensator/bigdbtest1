CREATE TYPE [dbo].[CreditBureauDirectConfig] AS TABLE(
	[Name] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[BureauName] [nvarchar](10) COLLATE Latin1_General_CI_AS NULL,
	[BureauCode] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[Version] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[IsBusinessBureau] [bit] NOT NULL,
	[PortfolioId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
