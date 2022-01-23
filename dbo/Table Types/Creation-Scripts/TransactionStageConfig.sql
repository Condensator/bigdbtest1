CREATE TYPE [dbo].[TransactionStageConfig] AS TABLE(
	[Name] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[Label] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsParallel] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[TransactionConfigId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
