SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BookDepreciations](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[CostBasis_Amount] [decimal](16, 2) NOT NULL,
	[CostBasis_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Salvage_Amount] [decimal](16, 2) NOT NULL,
	[Salvage_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[BeginDate] [date] NOT NULL,
	[EndDate] [date] NOT NULL,
	[RemainingLifeInMonths] [int] NOT NULL,
	[PerDayDepreciationFactor] [decimal](18, 8) NOT NULL,
	[TerminatedDate] [date] NULL,
	[IsActive] [bit] NOT NULL,
	[IsInOTP] [bit] NOT NULL,
	[LastAmortRunDate] [date] NULL,
	[ReversalPostDate] [date] NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[AssetId] [bigint] NOT NULL,
	[ContractId] [bigint] NULL,
	[GLTemplateId] [bigint] NOT NULL,
	[ClearAccumulatedGLJournalId] [bigint] NULL,
	[InstrumentTypeId] [bigint] NOT NULL,
	[LineofBusinessId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[CostCenterId] [bigint] NULL,
	[BookDepreciationTemplateId] [bigint] NULL,
	[BranchId] [bigint] NULL,
	[IsLessorOwned] [bit] NOT NULL,
	[IsLeaseComponent] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[BookDepreciations]  WITH CHECK ADD  CONSTRAINT [EBookDepreciation_Asset] FOREIGN KEY([AssetId])
REFERENCES [dbo].[Assets] ([Id])
GO
ALTER TABLE [dbo].[BookDepreciations] CHECK CONSTRAINT [EBookDepreciation_Asset]
GO
ALTER TABLE [dbo].[BookDepreciations]  WITH CHECK ADD  CONSTRAINT [EBookDepreciation_BookDepreciationTemplate] FOREIGN KEY([BookDepreciationTemplateId])
REFERENCES [dbo].[BookDepreciationTemplates] ([Id])
GO
ALTER TABLE [dbo].[BookDepreciations] CHECK CONSTRAINT [EBookDepreciation_BookDepreciationTemplate]
GO
ALTER TABLE [dbo].[BookDepreciations]  WITH CHECK ADD  CONSTRAINT [EBookDepreciation_Branch] FOREIGN KEY([BranchId])
REFERENCES [dbo].[Branches] ([Id])
GO
ALTER TABLE [dbo].[BookDepreciations] CHECK CONSTRAINT [EBookDepreciation_Branch]
GO
ALTER TABLE [dbo].[BookDepreciations]  WITH CHECK ADD  CONSTRAINT [EBookDepreciation_ClearAccumulatedGLJournal] FOREIGN KEY([ClearAccumulatedGLJournalId])
REFERENCES [dbo].[GLJournals] ([Id])
GO
ALTER TABLE [dbo].[BookDepreciations] CHECK CONSTRAINT [EBookDepreciation_ClearAccumulatedGLJournal]
GO
ALTER TABLE [dbo].[BookDepreciations]  WITH CHECK ADD  CONSTRAINT [EBookDepreciation_Contract] FOREIGN KEY([ContractId])
REFERENCES [dbo].[Contracts] ([Id])
GO
ALTER TABLE [dbo].[BookDepreciations] CHECK CONSTRAINT [EBookDepreciation_Contract]
GO
ALTER TABLE [dbo].[BookDepreciations]  WITH CHECK ADD  CONSTRAINT [EBookDepreciation_CostCenter] FOREIGN KEY([CostCenterId])
REFERENCES [dbo].[CostCenterConfigs] ([Id])
GO
ALTER TABLE [dbo].[BookDepreciations] CHECK CONSTRAINT [EBookDepreciation_CostCenter]
GO
ALTER TABLE [dbo].[BookDepreciations]  WITH CHECK ADD  CONSTRAINT [EBookDepreciation_GLTemplate] FOREIGN KEY([GLTemplateId])
REFERENCES [dbo].[GLTemplates] ([Id])
GO
ALTER TABLE [dbo].[BookDepreciations] CHECK CONSTRAINT [EBookDepreciation_GLTemplate]
GO
ALTER TABLE [dbo].[BookDepreciations]  WITH CHECK ADD  CONSTRAINT [EBookDepreciation_InstrumentType] FOREIGN KEY([InstrumentTypeId])
REFERENCES [dbo].[InstrumentTypes] ([Id])
GO
ALTER TABLE [dbo].[BookDepreciations] CHECK CONSTRAINT [EBookDepreciation_InstrumentType]
GO
ALTER TABLE [dbo].[BookDepreciations]  WITH CHECK ADD  CONSTRAINT [EBookDepreciation_LineofBusiness] FOREIGN KEY([LineofBusinessId])
REFERENCES [dbo].[LineofBusinesses] ([Id])
GO
ALTER TABLE [dbo].[BookDepreciations] CHECK CONSTRAINT [EBookDepreciation_LineofBusiness]
GO
