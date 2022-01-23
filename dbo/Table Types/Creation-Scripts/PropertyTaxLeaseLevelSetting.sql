CREATE TYPE [dbo].[PropertyTaxLeaseLevelSetting] AS TABLE(
	[UniqueIdentifier] [bigint] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[IncludeInExtract] [bit] NOT NULL,
	[IncludeAllPPTExemptCodes] [bit] NOT NULL,
	[IsReportCSA] [bit] NOT NULL,
	[EffectiveFromDate] [date] NOT NULL,
	[EffectiveToDate] [date] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[PortfolioId] [bigint] NOT NULL,
	[ContractId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
