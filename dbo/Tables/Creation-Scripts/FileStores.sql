SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[FileStores](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Source] [nvarchar](4000) COLLATE Latin1_General_CI_AS NOT NULL,
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
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
