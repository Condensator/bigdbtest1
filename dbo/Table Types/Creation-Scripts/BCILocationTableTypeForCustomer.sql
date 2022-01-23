CREATE TYPE [dbo].[BCILocationTableTypeForCustomer] AS TABLE(
	[AssetId] [bigint] NULL,
	[AssetLocationId] [bigint] NULL,
	[EffectiveFromDate] [date] NULL,
	[LocationId] [bigint] NULL,
	[ReceivableDetailId] [bigint] NULL,
	[ReceivableId] [bigint] NULL
)
GO
