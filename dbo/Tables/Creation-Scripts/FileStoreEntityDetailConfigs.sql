SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[FileStoreEntityDetailConfigs](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[StorageSystem] [nvarchar](19) COLLATE Latin1_General_CI_AS NULL,
	[PriorityRuleExpression] [nvarchar](1000) COLLATE Latin1_General_CI_AS NULL,
	[Path] [nvarchar](4000) COLLATE Latin1_General_CI_AS NOT NULL,
	[Priority] [int] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[FileStoreEntityConfigId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[FileStoreEntityDetailConfigs]  WITH CHECK ADD  CONSTRAINT [EFileStoreEntityConfig_FileStoreEntityDetailConfigs] FOREIGN KEY([FileStoreEntityConfigId])
REFERENCES [dbo].[FileStoreEntityConfigs] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[FileStoreEntityDetailConfigs] CHECK CONSTRAINT [EFileStoreEntityConfig_FileStoreEntityDetailConfigs]
GO
