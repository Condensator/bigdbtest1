SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TaxDepEntityEnMasseUpdateDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsComputationPending] [bit] NOT NULL,
	[TaxBasisAmount_Amount] [decimal](16, 2) NOT NULL,
	[TaxBasisAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[DepreciationBeginDate] [date] NOT NULL,
	[DepreciationEndDate] [date] NULL,
	[IsStraightLineMethodUsed] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[IsTaxDepreciationTerminated] [bit] NOT NULL,
	[TerminationDate] [date] NULL,
	[IsConditionalSale] [bit] NOT NULL,
	[Description] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[FXTaxBasisAmountInLE_Amount] [decimal](16, 2) NOT NULL,
	[FXTaxBasisAmountInLE_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[FXTaxBasisAmountInUSD_Amount] [decimal](16, 2) NOT NULL,
	[FXTaxBasisAmountInUSD_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[TaxDepreciationTemplateId] [bigint] NOT NULL,
	[AssetId] [bigint] NULL,
	[ContractId] [bigint] NULL,
	[TaxDepEntityEnMasseUpdateId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[TaxDepDisposalGLTemplateId] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[TaxDepEntityEnMasseUpdateDetails]  WITH CHECK ADD  CONSTRAINT [ETaxDepEntityEnMasseUpdate_TaxDepEntityEnMasseUpdateDetails] FOREIGN KEY([TaxDepEntityEnMasseUpdateId])
REFERENCES [dbo].[TaxDepEntityEnMasseUpdates] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[TaxDepEntityEnMasseUpdateDetails] CHECK CONSTRAINT [ETaxDepEntityEnMasseUpdate_TaxDepEntityEnMasseUpdateDetails]
GO
ALTER TABLE [dbo].[TaxDepEntityEnMasseUpdateDetails]  WITH CHECK ADD  CONSTRAINT [ETaxDepEntityEnMasseUpdateDetail_Asset] FOREIGN KEY([AssetId])
REFERENCES [dbo].[Assets] ([Id])
GO
ALTER TABLE [dbo].[TaxDepEntityEnMasseUpdateDetails] CHECK CONSTRAINT [ETaxDepEntityEnMasseUpdateDetail_Asset]
GO
ALTER TABLE [dbo].[TaxDepEntityEnMasseUpdateDetails]  WITH CHECK ADD  CONSTRAINT [ETaxDepEntityEnMasseUpdateDetail_Contract] FOREIGN KEY([ContractId])
REFERENCES [dbo].[Contracts] ([Id])
GO
ALTER TABLE [dbo].[TaxDepEntityEnMasseUpdateDetails] CHECK CONSTRAINT [ETaxDepEntityEnMasseUpdateDetail_Contract]
GO
ALTER TABLE [dbo].[TaxDepEntityEnMasseUpdateDetails]  WITH CHECK ADD  CONSTRAINT [ETaxDepEntityEnMasseUpdateDetail_TaxDepDisposalGLTemplate] FOREIGN KEY([TaxDepDisposalGLTemplateId])
REFERENCES [dbo].[GLTemplates] ([Id])
GO
ALTER TABLE [dbo].[TaxDepEntityEnMasseUpdateDetails] CHECK CONSTRAINT [ETaxDepEntityEnMasseUpdateDetail_TaxDepDisposalGLTemplate]
GO
ALTER TABLE [dbo].[TaxDepEntityEnMasseUpdateDetails]  WITH CHECK ADD  CONSTRAINT [ETaxDepEntityEnMasseUpdateDetail_TaxDepreciationTemplate] FOREIGN KEY([TaxDepreciationTemplateId])
REFERENCES [dbo].[TaxDepTemplates] ([Id])
GO
ALTER TABLE [dbo].[TaxDepEntityEnMasseUpdateDetails] CHECK CONSTRAINT [ETaxDepEntityEnMasseUpdateDetail_TaxDepreciationTemplate]
GO
