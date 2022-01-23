CREATE TYPE [dbo].[CostType] AS TABLE(
	[Name] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[IsSoft] [bit] NOT NULL,
	[IsShortfall] [bit] NOT NULL,
	[IsDefault] [bit] NOT NULL,
	[IsAsset] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[Type] [nvarchar](16) COLLATE Latin1_General_CI_AS NULL,
	[PortfolioId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
