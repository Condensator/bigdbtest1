CREATE TYPE [dbo].[TaxLocationIdentifier] AS TABLE(
	[JurisdictionId] [bigint] NULL,
	[LineItemNumber] [int] NULL,
	[DueDate] [date] NULL,
	[ReceivableTypeId] [bigint] NULL,
	[LocationId] [bigint] NULL,
	[StateTaxtypeId] [bigint] NULL,
	[CityTaxTypeId] [bigint] NULL,
	[CountyTaxTypeId] [bigint] NULL,
	[IsCountryTaxExempt] [bit] NULL,
	[IsStateTaxExempt] [bit] NULL,
	[IsCountyTaxExempt] [bit] NULL,
	[IsCityTaxExempt] [bit] NULL
)
GO
