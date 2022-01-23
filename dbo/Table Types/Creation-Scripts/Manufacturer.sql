CREATE TYPE [dbo].[Manufacturer] AS TABLE(
	[Name] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[IsActive] [bit] NOT NULL,
	[Class1] [nvarchar](6) COLLATE Latin1_General_CI_AS NOT NULL,
	[Description] [nvarchar](2000) COLLATE Latin1_General_CI_AS NULL,
	[PortfolioId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
