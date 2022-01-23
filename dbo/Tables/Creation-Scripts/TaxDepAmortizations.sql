SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TaxDepAmortizations](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[TaxBasisAmount_Amount] [decimal](16, 2) NOT NULL,
	[TaxBasisAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[FXTaxBasisAmount_Amount] [decimal](16, 2) NOT NULL,
	[FXTaxBasisAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[DepreciationBeginDate] [date] NOT NULL,
	[IsStraightLineMethodUsed] [bit] NOT NULL,
	[IsTaxDepreciationTerminated] [bit] NOT NULL,
	[TerminationDate] [date] NULL,
	[IsConditionalSale] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[TaxDepreciationTemplateId] [bigint] NOT NULL,
	[TaxDepEntityId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[TaxDepAmortizations]  WITH CHECK ADD  CONSTRAINT [ETaxDepAmortization_TaxDepEntity] FOREIGN KEY([TaxDepEntityId])
REFERENCES [dbo].[TaxDepEntities] ([Id])
GO
ALTER TABLE [dbo].[TaxDepAmortizations] CHECK CONSTRAINT [ETaxDepAmortization_TaxDepEntity]
GO
ALTER TABLE [dbo].[TaxDepAmortizations]  WITH CHECK ADD  CONSTRAINT [ETaxDepAmortization_TaxDepreciationTemplate] FOREIGN KEY([TaxDepreciationTemplateId])
REFERENCES [dbo].[TaxDepTemplates] ([Id])
GO
ALTER TABLE [dbo].[TaxDepAmortizations] CHECK CONSTRAINT [ETaxDepAmortization_TaxDepreciationTemplate]
GO
