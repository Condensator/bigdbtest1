CREATE TYPE [dbo].[LeaseIncomeRecognitionJobExtract] AS TABLE(
	[LeaseFinanceId] [bigint] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[TaskChunkServiceInstanceId] [bigint] NULL,
	[JobStepInstanceId] [bigint] NOT NULL,
	[PostDate] [date] NULL,
	[ProcessThroughDate] [date] NULL,
	[IsSubmitted] [bit] NOT NULL,
	[AssetCount] [int] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
