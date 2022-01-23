SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BlendedItems](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](50) COLLATE Latin1_General_CI_AS NOT NULL,
	[RowNumber] [int] NOT NULL,
	[EntityType] [nvarchar](11) COLLATE Latin1_General_CI_AS NOT NULL,
	[Amount_Amount] [decimal](16, 2) NOT NULL,
	[Amount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[StartDate] [date] NULL,
	[EndDate] [date] NULL,
	[CurrentEndDate] [date] NULL,
	[DueDate] [date] NULL,
	[DueDay] [int] NULL,
	[Frequency] [nvarchar](13) COLLATE Latin1_General_CI_AS NULL,
	[FrequencyUnit] [int] NULL,
	[Occurrence] [nvarchar](9) COLLATE Latin1_General_CI_AS NOT NULL,
	[NumberOfPayments] [int] NOT NULL,
	[NumberOfReceivablesGenerated] [int] NOT NULL,
	[Type] [nvarchar](7) COLLATE Latin1_General_CI_AS NOT NULL,
	[DeferRecognition] [bit] NOT NULL,
	[IsAssetBased] [bit] NOT NULL,
	[IsFAS91] [bit] NOT NULL,
	[IncludeInClassificationTest] [bit] NOT NULL,
	[IncludeInBlendedYield] [bit] NOT NULL,
	[Description] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[AccumulateExpense] [bit] NOT NULL,
	[BookRecognitionMode] [nvarchar](20) COLLATE Latin1_General_CI_AS NOT NULL,
	[RecognitionMethod] [nvarchar](17) COLLATE Latin1_General_CI_AS NULL,
	[ExpenseRecognitionMode] [nvarchar](11) COLLATE Latin1_General_CI_AS NULL,
	[TaxRecognitionMode] [nvarchar](20) COLLATE Latin1_General_CI_AS NULL,
	[GeneratePayableOrReceivable] [bit] NOT NULL,
	[InvoiceReceivableGroupingOption] [nvarchar](8) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[IsNewlyAdded] [bit] NOT NULL,
	[PostDate] [date] NULL,
	[SystemConfigType] [nvarchar](36) COLLATE Latin1_General_CI_AS NULL,
	[IsSystemGenerated] [bit] NOT NULL,
	[IsVendorSubsidy] [bit] NOT NULL,
	[IsVendorCommission] [bit] NOT NULL,
	[IsETC] [bit] NOT NULL,
	[TaxCreditTaxBasisPercentage] [decimal](5, 2) NOT NULL,
	[EarnedAmount_Amount] [decimal](16, 2) NOT NULL,
	[EarnedAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[AmountBilled_Amount] [decimal](16, 2) NOT NULL,
	[AmountBilled_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ParentBlendedItemId] [bigint] NULL,
	[BlendedItemCodeId] [bigint] NULL,
	[ReceivableCodeId] [bigint] NULL,
	[PayableCodeId] [bigint] NULL,
	[LeaseAssetId] [bigint] NULL,
	[LocationId] [bigint] NULL,
	[BillToId] [bigint] NULL,
	[PayableRemitToId] [bigint] NULL,
	[BookingGLTemplateId] [bigint] NULL,
	[RecognitionGLTemplateId] [bigint] NULL,
	[TaxDepTemplateId] [bigint] NULL,
	[PartyId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[IsFromST] [bit] NOT NULL,
	[ReceivableRemitToId] [bigint] NULL,
	[RelatedBlendedItemId] [bigint] NULL,
	[PayableWithholdingTaxRate] [decimal](5, 2) NULL,
	[VATAmount_Amount] [decimal](16, 2) NOT NULL,
	[VATAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[BlendedItems]  WITH CHECK ADD  CONSTRAINT [EBlendedItem_BillTo] FOREIGN KEY([BillToId])
REFERENCES [dbo].[BillToes] ([Id])
GO
ALTER TABLE [dbo].[BlendedItems] CHECK CONSTRAINT [EBlendedItem_BillTo]
GO
ALTER TABLE [dbo].[BlendedItems]  WITH CHECK ADD  CONSTRAINT [EBlendedItem_BlendedItemCode] FOREIGN KEY([BlendedItemCodeId])
REFERENCES [dbo].[BlendedItemCodes] ([Id])
GO
ALTER TABLE [dbo].[BlendedItems] CHECK CONSTRAINT [EBlendedItem_BlendedItemCode]
GO
ALTER TABLE [dbo].[BlendedItems]  WITH CHECK ADD  CONSTRAINT [EBlendedItem_BookingGLTemplate] FOREIGN KEY([BookingGLTemplateId])
REFERENCES [dbo].[GLTemplates] ([Id])
GO
ALTER TABLE [dbo].[BlendedItems] CHECK CONSTRAINT [EBlendedItem_BookingGLTemplate]
GO
ALTER TABLE [dbo].[BlendedItems]  WITH CHECK ADD  CONSTRAINT [EBlendedItem_LeaseAsset] FOREIGN KEY([LeaseAssetId])
REFERENCES [dbo].[LeaseAssets] ([Id])
GO
ALTER TABLE [dbo].[BlendedItems] CHECK CONSTRAINT [EBlendedItem_LeaseAsset]
GO
ALTER TABLE [dbo].[BlendedItems]  WITH CHECK ADD  CONSTRAINT [EBlendedItem_Location] FOREIGN KEY([LocationId])
REFERENCES [dbo].[Locations] ([Id])
GO
ALTER TABLE [dbo].[BlendedItems] CHECK CONSTRAINT [EBlendedItem_Location]
GO
ALTER TABLE [dbo].[BlendedItems]  WITH CHECK ADD  CONSTRAINT [EBlendedItem_ParentBlendedItem] FOREIGN KEY([ParentBlendedItemId])
REFERENCES [dbo].[BlendedItems] ([Id])
GO
ALTER TABLE [dbo].[BlendedItems] CHECK CONSTRAINT [EBlendedItem_ParentBlendedItem]
GO
ALTER TABLE [dbo].[BlendedItems]  WITH CHECK ADD  CONSTRAINT [EBlendedItem_Party] FOREIGN KEY([PartyId])
REFERENCES [dbo].[Parties] ([Id])
GO
ALTER TABLE [dbo].[BlendedItems] CHECK CONSTRAINT [EBlendedItem_Party]
GO
ALTER TABLE [dbo].[BlendedItems]  WITH CHECK ADD  CONSTRAINT [EBlendedItem_PayableCode] FOREIGN KEY([PayableCodeId])
REFERENCES [dbo].[PayableCodes] ([Id])
GO
ALTER TABLE [dbo].[BlendedItems] CHECK CONSTRAINT [EBlendedItem_PayableCode]
GO
ALTER TABLE [dbo].[BlendedItems]  WITH CHECK ADD  CONSTRAINT [EBlendedItem_PayableRemitTo] FOREIGN KEY([PayableRemitToId])
REFERENCES [dbo].[RemitToes] ([Id])
GO
ALTER TABLE [dbo].[BlendedItems] CHECK CONSTRAINT [EBlendedItem_PayableRemitTo]
GO
ALTER TABLE [dbo].[BlendedItems]  WITH CHECK ADD  CONSTRAINT [EBlendedItem_ReceivableCode] FOREIGN KEY([ReceivableCodeId])
REFERENCES [dbo].[ReceivableCodes] ([Id])
GO
ALTER TABLE [dbo].[BlendedItems] CHECK CONSTRAINT [EBlendedItem_ReceivableCode]
GO
ALTER TABLE [dbo].[BlendedItems]  WITH CHECK ADD  CONSTRAINT [EBlendedItem_ReceivableRemitTo] FOREIGN KEY([ReceivableRemitToId])
REFERENCES [dbo].[RemitToes] ([Id])
GO
ALTER TABLE [dbo].[BlendedItems] CHECK CONSTRAINT [EBlendedItem_ReceivableRemitTo]
GO
ALTER TABLE [dbo].[BlendedItems]  WITH CHECK ADD  CONSTRAINT [EBlendedItem_RecognitionGLTemplate] FOREIGN KEY([RecognitionGLTemplateId])
REFERENCES [dbo].[GLTemplates] ([Id])
GO
ALTER TABLE [dbo].[BlendedItems] CHECK CONSTRAINT [EBlendedItem_RecognitionGLTemplate]
GO
ALTER TABLE [dbo].[BlendedItems]  WITH CHECK ADD  CONSTRAINT [EBlendedItem_RelatedBlendedItem] FOREIGN KEY([RelatedBlendedItemId])
REFERENCES [dbo].[BlendedItems] ([Id])
GO
ALTER TABLE [dbo].[BlendedItems] CHECK CONSTRAINT [EBlendedItem_RelatedBlendedItem]
GO
ALTER TABLE [dbo].[BlendedItems]  WITH CHECK ADD  CONSTRAINT [EBlendedItem_TaxDepTemplate] FOREIGN KEY([TaxDepTemplateId])
REFERENCES [dbo].[TaxDepTemplates] ([Id])
GO
ALTER TABLE [dbo].[BlendedItems] CHECK CONSTRAINT [EBlendedItem_TaxDepTemplate]
GO
