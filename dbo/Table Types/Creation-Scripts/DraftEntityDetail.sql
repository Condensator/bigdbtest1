CREATE TYPE [dbo].[DraftEntityDetail] AS TABLE(
	[Data] [nvarchar](max) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[LookupKey] [nvarchar](500) COLLATE Latin1_General_CI_AS NOT NULL,
	[Status] [nvarchar](17) COLLATE Latin1_General_CI_AS NOT NULL,
	[ValidationMessages] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[EntityConversionErrors] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[TaskChunkServiceInstanceId] [bigint] NULL,
	[JobCorrelationId] [nvarchar](36) COLLATE Latin1_General_CI_AS NULL,
	[CreatedMode] [nvarchar](12) COLLATE Latin1_General_CI_AS NOT NULL,
	[DraftEntityBatchId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
