CREATE TYPE [dbo].[AMLMasterConfig] AS TABLE(
	[Name] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[IsHeader] [bit] NULL,
	[IsSubHeader] [bit] NULL,
	[IsCriteria] [bit] NULL,
	[IsChoiceApplicable] [bit] NULL,
	[IsCountryApplicable] [bit] NULL,
	[IsIndividual] [bit] NULL,
	[IsActive] [bit] NULL,
	[Order] [int] NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
