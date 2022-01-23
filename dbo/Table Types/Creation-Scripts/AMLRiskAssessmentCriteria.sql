CREATE TYPE [dbo].[AMLRiskAssessmentCriteria] AS TABLE(
	[IsActive] [bit] NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[Point] [decimal](16, 2) NULL,
	[AMLMasterConfigId] [bigint] NULL,
	[ChoiceId] [bigint] NULL,
	[CountryId] [bigint] NULL,
	[AMLRiskAssessmentId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
