CREATE TYPE [dbo].[TaxDepTemplateDetail] AS TABLE(
	[TaxBook] [nvarchar](7) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[DepreciationCostBasisPercent] [decimal](5, 2) NOT NULL,
	[BonusDepreciationPercent] [decimal](5, 2) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[TaxDepRateId] [bigint] NULL,
	[TaxDepTemplateId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
