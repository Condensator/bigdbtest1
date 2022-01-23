SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TaxDepEntities](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[EntityType] [nvarchar](14) COLLATE Latin1_General_CI_AS NOT NULL,
	[TaxBasisAmount_Amount] [decimal](16, 2) NOT NULL,
	[TaxBasisAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[FXTaxBasisAmount_Amount] [decimal](16, 2) NOT NULL,
	[FXTaxBasisAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[DepreciationBeginDate] [date] NOT NULL,
	[DepreciationEndDate] [date] NULL,
	[IsConditionalSale] [bit] NOT NULL,
	[IsStraightLineMethodUsed] [bit] NOT NULL,
	[IsTaxDepreciationTerminated] [bit] NOT NULL,
	[TerminationDate] [date] NULL,
	[IsActive] [bit] NOT NULL,
	[IsComputationPending] [bit] NOT NULL,
	[TerminatedByLeaseId] [bigint] NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[TaxDepTemplateId] [bigint] NOT NULL,
	[AssetId] [bigint] NULL,
	[BlendedItemId] [bigint] NULL,
	[ContractId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[IsGLPosted] [bit] NOT NULL,
	[PostDate] [date] NULL,
	[TaxDepDisposalTemplateId] [bigint] NULL,
	[TaxProceedsAmount_Amount] [decimal](16, 2) NOT NULL,
	[TaxProceedsAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[TaxDepEntities]  WITH CHECK ADD  CONSTRAINT [ETaxDepEntity_Asset] FOREIGN KEY([AssetId])
REFERENCES [dbo].[Assets] ([Id])
GO
ALTER TABLE [dbo].[TaxDepEntities] CHECK CONSTRAINT [ETaxDepEntity_Asset]
GO
ALTER TABLE [dbo].[TaxDepEntities]  WITH CHECK ADD  CONSTRAINT [ETaxDepEntity_BlendedItem] FOREIGN KEY([BlendedItemId])
REFERENCES [dbo].[BlendedItems] ([Id])
GO
ALTER TABLE [dbo].[TaxDepEntities] CHECK CONSTRAINT [ETaxDepEntity_BlendedItem]
GO
ALTER TABLE [dbo].[TaxDepEntities]  WITH CHECK ADD  CONSTRAINT [ETaxDepEntity_Contract] FOREIGN KEY([ContractId])
REFERENCES [dbo].[Contracts] ([Id])
GO
ALTER TABLE [dbo].[TaxDepEntities] CHECK CONSTRAINT [ETaxDepEntity_Contract]
GO
ALTER TABLE [dbo].[TaxDepEntities]  WITH CHECK ADD  CONSTRAINT [ETaxDepEntity_TaxDepDisposalTemplate] FOREIGN KEY([TaxDepDisposalTemplateId])
REFERENCES [dbo].[GLTemplates] ([Id])
GO
ALTER TABLE [dbo].[TaxDepEntities] CHECK CONSTRAINT [ETaxDepEntity_TaxDepDisposalTemplate]
GO
ALTER TABLE [dbo].[TaxDepEntities]  WITH CHECK ADD  CONSTRAINT [ETaxDepEntity_TaxDepTemplate] FOREIGN KEY([TaxDepTemplateId])
REFERENCES [dbo].[TaxDepTemplates] ([Id])
GO
ALTER TABLE [dbo].[TaxDepEntities] CHECK CONSTRAINT [ETaxDepEntity_TaxDepTemplate]
GO
