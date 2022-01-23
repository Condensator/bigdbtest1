CREATE TYPE [dbo].[StoredProcExecutionContext] AS TABLE(
	[UserId] [bigint] NOT NULL,
	[BusinessUnitId] [bigint] NOT NULL,
	[CurrentBusinessDate] [date] NOT NULL,
	[AccessibleLegalEntityIdsCsv] [nvarchar](max) COLLATE Latin1_General_CI_AS NOT NULL,
	[JobServiceId] [bigint] NULL,
	[JobInstanceId] [bigint] NULL,
	[JobStepInstanceId] [bigint] NULL,
	[IsValidationMode] [bit] NOT NULL
)
GO
