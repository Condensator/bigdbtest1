CREATE TYPE [dbo].[PropertyTaxExemptCode] AS TABLE(
	[UniqueIdentifier] [bigint] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[EffectiveFromDate] [date] NOT NULL,
	[EffectiveToDate] [date] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[StateId] [bigint] NOT NULL,
	[PropertyTaxReportCodeId] [bigint] NOT NULL,
	[PortfolioId] [bigint] NOT NULL,
	[PropertyTaxParameterId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
