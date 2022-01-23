SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AssetsValueStatusChangeDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[AdjustmentAmount_Amount] [decimal](16, 2) NOT NULL,
	[AdjustmentAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[NewStatus] [nvarchar](17) COLLATE Latin1_General_CI_AS NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[AssetId] [bigint] NOT NULL,
	[AssetsValueStatusChangeId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[GLJournalID] [bigint] NULL,
	[CostCenterId] [bigint] NULL,
	[GLTemplateId] [bigint] NULL,
	[InstrumentTypeId] [bigint] NULL,
	[LineofBusinessId] [bigint] NULL,
	[BookDepreciationTemplateId] [bigint] NULL,
	[ReversalGLJournalId] [bigint] NULL,
	[BranchId] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[AssetsValueStatusChangeDetails]  WITH CHECK ADD  CONSTRAINT [EAssetsValueStatusChange_AssetsValueStatusChangeDetails] FOREIGN KEY([AssetsValueStatusChangeId])
REFERENCES [dbo].[AssetsValueStatusChanges] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[AssetsValueStatusChangeDetails] CHECK CONSTRAINT [EAssetsValueStatusChange_AssetsValueStatusChangeDetails]
GO
ALTER TABLE [dbo].[AssetsValueStatusChangeDetails]  WITH CHECK ADD  CONSTRAINT [EAssetsValueStatusChangeDetail_Asset] FOREIGN KEY([AssetId])
REFERENCES [dbo].[Assets] ([Id])
GO
ALTER TABLE [dbo].[AssetsValueStatusChangeDetails] CHECK CONSTRAINT [EAssetsValueStatusChangeDetail_Asset]
GO
ALTER TABLE [dbo].[AssetsValueStatusChangeDetails]  WITH CHECK ADD  CONSTRAINT [EAssetsValueStatusChangeDetail_BookDepreciationTemplate] FOREIGN KEY([BookDepreciationTemplateId])
REFERENCES [dbo].[BookDepreciationTemplates] ([Id])
GO
ALTER TABLE [dbo].[AssetsValueStatusChangeDetails] CHECK CONSTRAINT [EAssetsValueStatusChangeDetail_BookDepreciationTemplate]
GO
ALTER TABLE [dbo].[AssetsValueStatusChangeDetails]  WITH CHECK ADD  CONSTRAINT [EAssetsValueStatusChangeDetail_Branch] FOREIGN KEY([BranchId])
REFERENCES [dbo].[Branches] ([Id])
GO
ALTER TABLE [dbo].[AssetsValueStatusChangeDetails] CHECK CONSTRAINT [EAssetsValueStatusChangeDetail_Branch]
GO
ALTER TABLE [dbo].[AssetsValueStatusChangeDetails]  WITH CHECK ADD  CONSTRAINT [EAssetsValueStatusChangeDetail_CostCenter] FOREIGN KEY([CostCenterId])
REFERENCES [dbo].[CostCenterConfigs] ([Id])
GO
ALTER TABLE [dbo].[AssetsValueStatusChangeDetails] CHECK CONSTRAINT [EAssetsValueStatusChangeDetail_CostCenter]
GO
ALTER TABLE [dbo].[AssetsValueStatusChangeDetails]  WITH CHECK ADD  CONSTRAINT [EAssetsValueStatusChangeDetail_GLJournal] FOREIGN KEY([GLJournalID])
REFERENCES [dbo].[GLJournals] ([Id])
GO
ALTER TABLE [dbo].[AssetsValueStatusChangeDetails] CHECK CONSTRAINT [EAssetsValueStatusChangeDetail_GLJournal]
GO
ALTER TABLE [dbo].[AssetsValueStatusChangeDetails]  WITH CHECK ADD  CONSTRAINT [EAssetsValueStatusChangeDetail_GLTemplate] FOREIGN KEY([GLTemplateId])
REFERENCES [dbo].[GLTemplates] ([Id])
GO
ALTER TABLE [dbo].[AssetsValueStatusChangeDetails] CHECK CONSTRAINT [EAssetsValueStatusChangeDetail_GLTemplate]
GO
ALTER TABLE [dbo].[AssetsValueStatusChangeDetails]  WITH CHECK ADD  CONSTRAINT [EAssetsValueStatusChangeDetail_InstrumentType] FOREIGN KEY([InstrumentTypeId])
REFERENCES [dbo].[InstrumentTypes] ([Id])
GO
ALTER TABLE [dbo].[AssetsValueStatusChangeDetails] CHECK CONSTRAINT [EAssetsValueStatusChangeDetail_InstrumentType]
GO
ALTER TABLE [dbo].[AssetsValueStatusChangeDetails]  WITH CHECK ADD  CONSTRAINT [EAssetsValueStatusChangeDetail_LineofBusiness] FOREIGN KEY([LineofBusinessId])
REFERENCES [dbo].[LineofBusinesses] ([Id])
GO
ALTER TABLE [dbo].[AssetsValueStatusChangeDetails] CHECK CONSTRAINT [EAssetsValueStatusChangeDetail_LineofBusiness]
GO
ALTER TABLE [dbo].[AssetsValueStatusChangeDetails]  WITH CHECK ADD  CONSTRAINT [EAssetsValueStatusChangeDetail_ReversalGLJournal] FOREIGN KEY([ReversalGLJournalId])
REFERENCES [dbo].[GLJournals] ([Id])
GO
ALTER TABLE [dbo].[AssetsValueStatusChangeDetails] CHECK CONSTRAINT [EAssetsValueStatusChangeDetail_ReversalGLJournal]
GO
