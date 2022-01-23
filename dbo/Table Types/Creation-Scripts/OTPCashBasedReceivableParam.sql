CREATE TYPE [dbo].[OTPCashBasedReceivableParam] AS TABLE(
	[LeaseContractType] [varchar](16) COLLATE Latin1_General_CI_AS NULL,
	[DepreciationAmount] [decimal](16, 2) NULL,
	[IncomeAmount] [decimal](16, 2) NULL,
	[EntityId] [bigint] NULL,
	[InstrumentTypeId] [bigint] NULL,
	[LineOfBusinessId] [bigint] NULL,
	[GLTemplateId] [bigint] NULL,
	[OTPARGLTemplateId] [bigint] NULL,
	[CanUpdateHeaderGLJournal] [bit] NULL,
	[CanUpdateIncomeScheduleGL] [bit] NULL,
	[AssetId] [bigint] NULL,
	[LeaseIncomeScheduleIdsInCSV] [varchar](max) COLLATE Latin1_General_CI_AS NULL,
	[AssetValueHistoryId] [bigint] NULL,
	[IncomeType] [nvarchar](16) COLLATE Latin1_General_CI_AS NULL,
	[IsNonAccrual] [bit] NULL,
	[ReceivableDetailId] [bigint] NULL
)
GO
