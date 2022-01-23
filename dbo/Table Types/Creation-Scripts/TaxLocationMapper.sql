CREATE TYPE [dbo].[TaxLocationMapper] AS TABLE(
	[JurisdictionId] [bigint] NULL,
	[AssetId] [bigint] NULL,
	[ReceivableDetailId] [bigint] NULL,
	[DueDate] [date] NULL,
	[ReceivableTypeId] [bigint] NULL,
	[ReceivableCodeId] [bigint] NULL,
	[LocationId] [bigint] NULL,
	[ReceivableId] [bigint] NULL,
	[ContractId] [bigint] NULL,
	[LeaseFinanceId] [bigint] NULL,
	[TaxTypeId] [bigint] NULL,
	[StateTaxtypeId] [bigint] NULL,
	[CityTaxTypeId] [bigint] NULL,
	[CountyTaxTypeId] [bigint] NULL
)
GO
