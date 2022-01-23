CREATE TYPE [dbo].[AutoActionLog] AS TABLE(
	[JobStepInstanceId] [bigint] NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[EntitySelectionSQL] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[UpdateSQL] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[MasterSQL] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[AutoActionTemplateId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
