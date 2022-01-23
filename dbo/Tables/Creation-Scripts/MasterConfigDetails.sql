SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[MasterConfigDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[ConfigType] [nvarchar](31) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[ProcessingOrder] [decimal](16, 2) NOT NULL,
	[IsRoot] [bit] NOT NULL,
	[DynamicFilterConditions] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[NonEditableColumns] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[CanAddRows] [bit] NOT NULL,
	[RowSecurityConditions] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[CreateTransactionName] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[EditTransactionName] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[MasterConfigEntityId] [bigint] NOT NULL,
	[MasterConfigId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[TransactionScriptName] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[SelectorName] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[MasterConfigDetails]  WITH CHECK ADD  CONSTRAINT [EMasterConfig_MasterConfigDetails] FOREIGN KEY([MasterConfigId])
REFERENCES [dbo].[MasterConfigs] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[MasterConfigDetails] CHECK CONSTRAINT [EMasterConfig_MasterConfigDetails]
GO
ALTER TABLE [dbo].[MasterConfigDetails]  WITH CHECK ADD  CONSTRAINT [EMasterConfigDetail_MasterConfigEntity] FOREIGN KEY([MasterConfigEntityId])
REFERENCES [dbo].[MasterConfigEntities] ([Id])
GO
ALTER TABLE [dbo].[MasterConfigDetails] CHECK CONSTRAINT [EMasterConfigDetail_MasterConfigEntity]
GO
