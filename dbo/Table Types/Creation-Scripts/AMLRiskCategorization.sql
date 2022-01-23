CREATE TYPE [dbo].[AMLRiskCategorization] AS TABLE(
	[Adjustment] [decimal](5, 2) NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[Point] [decimal](16, 2) NULL,
	[Category] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NULL,
	[AMLRiskCategoryConfigId] [bigint] NULL,
	[AMLRiskAssessmentId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
