CREATE TYPE [dbo].[FileStore] AS TABLE(
	[Source] [nvarchar](4000) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[FileType] [nvarchar](10) COLLATE Latin1_General_CI_AS NOT NULL,
	[GUID] [uniqueidentifier] NOT NULL,
	[StorageSystem] [nvarchar](19) COLLATE Latin1_General_CI_AS NOT NULL,
	[Content] [varbinary](max) NULL,
	[ExtStoreReference] [nvarchar](4000) COLLATE Latin1_General_CI_AS NULL,
	[AccessKey] [nvarchar](20) COLLATE Latin1_General_CI_AS NULL,
	[SourceEntity] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[SourceEntityId] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[SourceSystem] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[IsContentProcessed] [bit] NOT NULL,
	[IsPreserveContentInLocal] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
