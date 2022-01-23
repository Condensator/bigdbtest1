CREATE TYPE [dbo].[AssetsValueStatusChangeDetail] AS TABLE(
	[AdjustmentAmount_Amount] [decimal](16, 2) NOT NULL,
	[AdjustmentAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[NewStatus] [nvarchar](17) COLLATE Latin1_General_CI_AS NOT NULL,
	[AssetId] [bigint] NOT NULL,
	[GLJournalId] [bigint] NULL,
	[ReversalGLJournalId] [bigint] NULL,
	[GLTemplateId] [bigint] NULL,
	[InstrumentTypeId] [bigint] NULL,
	[LineofBusinessId] [bigint] NULL,
	[CostCenterId] [bigint] NULL,
	[BranchId] [bigint] NULL,
	[BookDepreciationTemplateId] [bigint] NULL,
	[AssetsValueStatusChangeId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
