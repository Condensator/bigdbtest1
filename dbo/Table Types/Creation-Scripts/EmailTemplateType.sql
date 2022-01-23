CREATE TYPE [dbo].[EmailTemplateType] AS TABLE(
	[Name] [nvarchar](39) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[AreMultipleTemplatesAllowed] [bit] NOT NULL,
	[IsPortfolioApplicable] [bit] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
