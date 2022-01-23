CREATE TYPE [dbo].[AssetTypeResidualConfig] AS TABLE(
	[Term] [int] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[MaxResidualPercentage] [decimal](5, 2) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[AssetTypeId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
