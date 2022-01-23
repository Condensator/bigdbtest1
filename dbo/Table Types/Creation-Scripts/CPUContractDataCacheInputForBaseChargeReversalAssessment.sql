CREATE TYPE [dbo].[CPUContractDataCacheInputForBaseChargeReversalAssessment] AS TABLE(
	[CPUContractId] [bigint] NOT NULL,
	[CPUScheduleId] [bigint] NOT NULL,
	[CPUAssetIds] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[ReverseFrom] [date] NULL
)
GO
