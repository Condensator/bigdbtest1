CREATE TYPE [dbo].[CPUContractDataCacheInputForOverageChargeReversalAssessment] AS TABLE(
	[CPUContractId] [bigint] NOT NULL,
	[CPUScheduleId] [bigint] NOT NULL,
	[CPUAssetIds] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[ReverseFrom] [date] NULL
)
GO
