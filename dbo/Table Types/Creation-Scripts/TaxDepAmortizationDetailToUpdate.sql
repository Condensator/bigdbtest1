CREATE TYPE [dbo].[TaxDepAmortizationDetailToUpdate] AS TABLE(
	[Id] [bigint] NULL,
	[IsSchedule] [bit] NULL,
	[IsAccounting] [bit] NULL,
	[IsGLPosted] [bit] NULL,
	[IsFromGLComponent] [bit] NULL
)
GO
