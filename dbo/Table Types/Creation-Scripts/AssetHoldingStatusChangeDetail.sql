CREATE TYPE [dbo].[AssetHoldingStatusChangeDetail] AS TABLE(
	[IsActive] [bit] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[AssetId] [bigint] NOT NULL,
	[LineofBusinessId] [bigint] NULL,
	[NewLineofBusinessId] [bigint] NULL,
	[InstrumentTypeId] [bigint] NULL,
	[NewInstrumentTypeId] [bigint] NULL,
	[CostCenterId] [bigint] NULL,
	[AssetHoldingStatusChangeId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
