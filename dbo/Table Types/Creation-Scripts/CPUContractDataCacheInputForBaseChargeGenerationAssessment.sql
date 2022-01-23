CREATE TYPE [dbo].[CPUContractDataCacheInputForBaseChargeGenerationAssessment] AS TABLE(
	[CPUContractId] [bigint] NOT NULL,
	[CPUScheduleId] [bigint] NOT NULL,
	[ComputedProcessThroughDate] [datetime] NOT NULL
)
GO
