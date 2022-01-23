CREATE TYPE [dbo].[FileStoreEntityDetailConfig] AS TABLE(
	[StorageSystem] [nvarchar](19) COLLATE Latin1_General_CI_AS NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[PriorityRuleExpression] [nvarchar](1000) COLLATE Latin1_General_CI_AS NULL,
	[Path] [nvarchar](4000) COLLATE Latin1_General_CI_AS NOT NULL,
	[Priority] [int] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[FileStoreEntityConfigId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
