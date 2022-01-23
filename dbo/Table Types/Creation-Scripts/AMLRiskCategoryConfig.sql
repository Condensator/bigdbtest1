CREATE TYPE [dbo].[AMLRiskCategoryConfig] AS TABLE(
	[Name] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[Adjustment] [decimal](16, 2) NULL,
	[IsIndividual] [bit] NULL,
	[IsActive] [bit] NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
