CREATE TYPE [dbo].[CPUContractDataCacheInputForOverageChargeGenerationAssessment] AS TABLE(
	[CPUContractId] [bigint] NOT NULL,
	[CPUScheduleId] [bigint] NOT NULL,
	[ComputedProcessThroughDate] [date] NOT NULL
)
GO
