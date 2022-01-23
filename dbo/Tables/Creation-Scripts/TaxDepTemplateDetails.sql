SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TaxDepTemplateDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[TaxBook] [nvarchar](7) COLLATE Latin1_General_CI_AS NOT NULL,
	[DepreciationCostBasisPercent] [decimal](5, 2) NOT NULL,
	[BonusDepreciationPercent] [decimal](5, 2) NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[TaxDepRateId] [bigint] NULL,
	[TaxDepTemplateId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[IsActive] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[TaxDepTemplateDetails]  WITH CHECK ADD  CONSTRAINT [ETaxDepTemplate_TaxDepTemplateDetails] FOREIGN KEY([TaxDepTemplateId])
REFERENCES [dbo].[TaxDepTemplates] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[TaxDepTemplateDetails] CHECK CONSTRAINT [ETaxDepTemplate_TaxDepTemplateDetails]
GO
ALTER TABLE [dbo].[TaxDepTemplateDetails]  WITH CHECK ADD  CONSTRAINT [ETaxDepTemplateDetail_TaxDepRate] FOREIGN KEY([TaxDepRateId])
REFERENCES [dbo].[TaxDepRates] ([Id])
GO
ALTER TABLE [dbo].[TaxDepTemplateDetails] CHECK CONSTRAINT [ETaxDepTemplateDetail_TaxDepRate]
GO
