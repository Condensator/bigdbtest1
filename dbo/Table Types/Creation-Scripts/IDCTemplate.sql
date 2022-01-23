CREATE TYPE [dbo].[IDCTemplate] AS TABLE(
	[IDCTemplateName] [nvarchar](30) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[FloorPercent] [decimal](5, 2) NULL,
	[CeilingPercent] [decimal](5, 2) NULL,
	[IsActive] [bit] NOT NULL,
	[IsDefault] [bit] NOT NULL,
	[GLConfigurationId] [bigint] NOT NULL,
	[BlendedItemCodeId] [bigint] NOT NULL,
	[PortfolioId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
