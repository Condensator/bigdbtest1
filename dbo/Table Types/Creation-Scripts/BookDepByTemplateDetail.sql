CREATE TYPE [dbo].[BookDepByTemplateDetail] AS TABLE(
	[AssetId] [bigint] NULL,
	[CostBasis] [decimal](16, 2) NULL,
	[Salvage] [decimal](16, 2) NULL,
	[BeginDate] [datetime] NULL,
	[EndDate] [datetime] NULL,
	[ContractId] [bigint] NULL,
	[IsInOTP] [bit] NULL,
	[PerDayDepreciationFactor] [decimal](16, 8) NULL,
	[Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[RemainingLifeInMonths] [int] NULL,
	[GLTemplateId] [bigint] NULL,
	[BookDepTemplateId] [bigint] NULL,
	[InstrumentTypeId] [bigint] NULL,
	[LineOfBusinessId] [bigint] NULL,
	[CostCenterId] [bigint] NULL,
	[IsLessorOwned] [bit] NULL,
	[IsLeaseComponent] [bit] NULL
)
GO
