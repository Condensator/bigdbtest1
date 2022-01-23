SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[MasterConfigSetDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[MasterConfigDetailId] [bigint] NOT NULL,
	[DraftEntityBatchId] [bigint] NOT NULL,
	[MasterConfigurationSetId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[MasterConfigSetDetails]  WITH CHECK ADD  CONSTRAINT [EMasterConfigSetDetail_DraftEntityBatch] FOREIGN KEY([DraftEntityBatchId])
REFERENCES [dbo].[DraftEntityBatches] ([Id])
GO
ALTER TABLE [dbo].[MasterConfigSetDetails] CHECK CONSTRAINT [EMasterConfigSetDetail_DraftEntityBatch]
GO
ALTER TABLE [dbo].[MasterConfigSetDetails]  WITH CHECK ADD  CONSTRAINT [EMasterConfigSetDetail_MasterConfigDetail] FOREIGN KEY([MasterConfigDetailId])
REFERENCES [dbo].[MasterConfigDetails] ([Id])
GO
ALTER TABLE [dbo].[MasterConfigSetDetails] CHECK CONSTRAINT [EMasterConfigSetDetail_MasterConfigDetail]
GO
ALTER TABLE [dbo].[MasterConfigSetDetails]  WITH CHECK ADD  CONSTRAINT [EMasterConfigurationSet_MasterConfigSetDetails] FOREIGN KEY([MasterConfigurationSetId])
REFERENCES [dbo].[MasterConfigurationSets] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[MasterConfigSetDetails] CHECK CONSTRAINT [EMasterConfigurationSet_MasterConfigSetDetails]
GO
