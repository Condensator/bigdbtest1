CREATE TYPE [dbo].[ManipulateAssetHoldingStatusParam] AS TABLE(
	[Id] [bigint] NULL,
	[NewInstrumentTypeId] [bigint] NULL,
	[NewLineofBusinessId] [bigint] NULL,
	[InstrumentTypeId] [bigint] NULL,
	[LineofBusinessid] [bigint] NULL
)
GO
