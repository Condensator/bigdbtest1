CREATE TYPE [dbo].[GLOrgStructureConfig] AS TABLE(
	[BusinessCode] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[BusinessCodeDescription] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[MORDate] [nvarchar](1) COLLATE Latin1_General_CI_AS NOT NULL,
	[OrgStructureComments] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[AnalysisCodeBasedOnCenter] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[AnalysisCodeBasedOnBizCode] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[CounterpartyAnalysisCodeBasedOnBizCodeAndLE] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[LegalEntityId] [bigint] NOT NULL,
	[LineofBusinessId] [bigint] NOT NULL,
	[CurrencyId] [bigint] NOT NULL,
	[CostCenterId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
