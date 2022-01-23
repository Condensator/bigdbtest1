CREATE TYPE [dbo].[TaxExemptRule] AS TABLE(
	[EntityType] [nvarchar](14) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[IsCountryTaxExempt] [bit] NOT NULL,
	[IsStateTaxExempt] [bit] NOT NULL,
	[IsCountyTaxExempt] [bit] NOT NULL,
	[IsCityTaxExempt] [bit] NOT NULL,
	[CountryExemptionNumber] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[StateExemptionNumber] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[TaxExemptionReasonId] [bigint] NULL,
	[StateTaxExemptionReasonId] [bigint] NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
