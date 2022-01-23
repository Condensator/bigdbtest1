SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ReceivableTypeBlendingConfigTables](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[EntityType] [nvarchar](5) COLLATE Latin1_General_CI_AS NOT NULL,
	[BlendContractTypes] [nvarchar](20) COLLATE Latin1_General_CI_AS NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[BlendReceivableSubTypeId] [bigint] NOT NULL,
	[BlendWithReceivableTypeId] [bigint] NOT NULL,
	[ReceivableTypeId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ReceivableTypeBlendingConfigTables]  WITH CHECK ADD  CONSTRAINT [EReceivableTypeBlendingConfigTable_BlendReceivableSubType] FOREIGN KEY([BlendReceivableSubTypeId])
REFERENCES [dbo].[ReceivableCategories] ([Id])
GO
ALTER TABLE [dbo].[ReceivableTypeBlendingConfigTables] CHECK CONSTRAINT [EReceivableTypeBlendingConfigTable_BlendReceivableSubType]
GO
ALTER TABLE [dbo].[ReceivableTypeBlendingConfigTables]  WITH CHECK ADD  CONSTRAINT [EReceivableTypeBlendingConfigTable_BlendWithReceivableType] FOREIGN KEY([BlendWithReceivableTypeId])
REFERENCES [dbo].[ReceivableTypes] ([Id])
GO
ALTER TABLE [dbo].[ReceivableTypeBlendingConfigTables] CHECK CONSTRAINT [EReceivableTypeBlendingConfigTable_BlendWithReceivableType]
GO
ALTER TABLE [dbo].[ReceivableTypeBlendingConfigTables]  WITH CHECK ADD  CONSTRAINT [EReceivableTypeBlendingConfigTable_ReceivableType] FOREIGN KEY([ReceivableTypeId])
REFERENCES [dbo].[ReceivableTypes] ([Id])
GO
ALTER TABLE [dbo].[ReceivableTypeBlendingConfigTables] CHECK CONSTRAINT [EReceivableTypeBlendingConfigTable_ReceivableType]
GO
