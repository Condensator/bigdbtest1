SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BlendedItemCodes](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[EntityType] [nvarchar](11) COLLATE Latin1_General_CI_AS NULL,
	[Type] [nvarchar](7) COLLATE Latin1_General_CI_AS NOT NULL,
	[BookRecognitionMode] [nvarchar](20) COLLATE Latin1_General_CI_AS NOT NULL,
	[RecognitionMethod] [nvarchar](17) COLLATE Latin1_General_CI_AS NULL,
	[AccumulateExpense] [bit] NOT NULL,
	[Occurrence] [nvarchar](9) COLLATE Latin1_General_CI_AS NOT NULL,
	[Frequency] [nvarchar](13) COLLATE Latin1_General_CI_AS NULL,
	[GeneratePayableOrReceivable] [bit] NOT NULL,
	[IsAssetBased] [bit] NOT NULL,
	[IsFAS91] [bit] NOT NULL,
	[IsVendorSubsidy] [bit] NOT NULL,
	[IncludeInClassificationTest] [bit] NOT NULL,
	[IncludeInBlendedYield] [bit] NOT NULL,
	[Description] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[TaxRecognitionMode] [nvarchar](20) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsVendorCommission] [bit] NOT NULL,
	[TaxCredit] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[TaxDepTemplateId] [bigint] NULL,
	[ReceivableCodeId] [bigint] NULL,
	[PayableCodeId] [bigint] NULL,
	[BookingGLTemplateId] [bigint] NOT NULL,
	[RecognitionGLTemplateId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[IncludeInPayoffOrPaydown] [bit] NOT NULL,
	[PortfolioId] [bigint] NOT NULL,
	[PayableWithholdingTaxRate] [decimal](5, 2) NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[BlendedItemCodes]  WITH CHECK ADD  CONSTRAINT [EBlendedItemCode_BookingGLTemplate] FOREIGN KEY([BookingGLTemplateId])
REFERENCES [dbo].[GLTemplates] ([Id])
GO
ALTER TABLE [dbo].[BlendedItemCodes] CHECK CONSTRAINT [EBlendedItemCode_BookingGLTemplate]
GO
ALTER TABLE [dbo].[BlendedItemCodes]  WITH CHECK ADD  CONSTRAINT [EBlendedItemCode_PayableCode] FOREIGN KEY([PayableCodeId])
REFERENCES [dbo].[PayableCodes] ([Id])
GO
ALTER TABLE [dbo].[BlendedItemCodes] CHECK CONSTRAINT [EBlendedItemCode_PayableCode]
GO
ALTER TABLE [dbo].[BlendedItemCodes]  WITH CHECK ADD  CONSTRAINT [EBlendedItemCode_Portfolio] FOREIGN KEY([PortfolioId])
REFERENCES [dbo].[Portfolios] ([Id])
GO
ALTER TABLE [dbo].[BlendedItemCodes] CHECK CONSTRAINT [EBlendedItemCode_Portfolio]
GO
ALTER TABLE [dbo].[BlendedItemCodes]  WITH CHECK ADD  CONSTRAINT [EBlendedItemCode_ReceivableCode] FOREIGN KEY([ReceivableCodeId])
REFERENCES [dbo].[ReceivableCodes] ([Id])
GO
ALTER TABLE [dbo].[BlendedItemCodes] CHECK CONSTRAINT [EBlendedItemCode_ReceivableCode]
GO
ALTER TABLE [dbo].[BlendedItemCodes]  WITH CHECK ADD  CONSTRAINT [EBlendedItemCode_RecognitionGLTemplate] FOREIGN KEY([RecognitionGLTemplateId])
REFERENCES [dbo].[GLTemplates] ([Id])
GO
ALTER TABLE [dbo].[BlendedItemCodes] CHECK CONSTRAINT [EBlendedItemCode_RecognitionGLTemplate]
GO
ALTER TABLE [dbo].[BlendedItemCodes]  WITH CHECK ADD  CONSTRAINT [EBlendedItemCode_TaxDepTemplate] FOREIGN KEY([TaxDepTemplateId])
REFERENCES [dbo].[TaxDepTemplates] ([Id])
GO
ALTER TABLE [dbo].[BlendedItemCodes] CHECK CONSTRAINT [EBlendedItemCode_TaxDepTemplate]
GO
