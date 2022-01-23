CREATE TYPE [dbo].[NonAccrualLeaseFloatRateIncomesToUpdate] AS TABLE(
	[Id] [bigint] NOT NULL,
	[IsScheduled] [bit] NOT NULL,
	[IsGLPosted] [bit] NOT NULL,
	[IsNonAccrual] [bit] NOT NULL
)
GO
