CREATE TYPE [dbo].[TaskChunkInstance] AS TABLE(
	[ComponentName] [nvarchar](250) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[Status] [nvarchar](19) COLLATE Latin1_General_CI_AS NOT NULL,
	[JobStepInstanceId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
