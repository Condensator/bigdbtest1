CREATE TYPE [dbo].[BooKDepreciationRecordTVP] AS TABLE(
	[AssetId] [bigint] NULL,
	[CostBasis] [decimal](16, 2) NULL,
	[Salvage] [decimal](16, 2) NULL,
	[BeginDate] [date] NULL,
	[EndDate] [date] NULL,
	[TerminatedDate] [date] NULL,
	[GLTemplateId] [bigint] NULL,
	[InstrumentTypeId] [bigint] NULL,
	[LineofBusinessId] [bigint] NULL,
	[CostCenterId] [bigint] NULL,
	[ContractId] [bigint] NULL,
	[IsActive] [bit] NULL,
	[PerDayDepreciationFactor] [decimal](18, 8) NULL,
	[IsLessorOwned] [bit] NULL,
	[Currency] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[IsLeaseComponent] [bit] NULL
)
GO
