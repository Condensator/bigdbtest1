SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PayableInvoiceOtherCosts](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[RowNumber] [int] NOT NULL,
	[AllocationMethod] [nvarchar](22) COLLATE Latin1_General_CI_AS NOT NULL,
	[Description] [nvarchar](200) COLLATE Latin1_General_CI_AS NOT NULL,
	[Amount_Amount] [decimal](16, 2) NOT NULL,
	[Amount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[DueDate] [date] NULL,
	[IsLeaseCostAdjusted] [bit] NOT NULL,
	[InterimInterestStartDate] [date] NULL,
	[InterestUpdateLastDate] [date] NULL,
	[CreditBalance_Amount] [decimal](16, 2) NOT NULL,
	[CreditBalance_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsUpfit] [bit] NOT NULL,
	[CapitalizeFrom] [nvarchar](16) COLLATE Latin1_General_CI_AS NULL,
	[AssociateAssets] [bit] NOT NULL,
	[Comment] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[CapitalizedProgressPayment_Amount] [decimal](16, 2) NOT NULL,
	[CapitalizedProgressPayment_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsPaydownCompleted] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[OtherCostCodeId] [bigint] NULL,
	[OtherCostPayableCodeId] [bigint] NULL,
	[ReceivableCodeId] [bigint] NULL,
	[RemitToId] [bigint] NULL,
	[BillToId] [bigint] NULL,
	[LocationId] [bigint] NULL,
	[VendorId] [bigint] NOT NULL,
	[ContractId] [bigint] NULL,
	[SundryReceivableId] [bigint] NULL,
	[GLJournalId] [bigint] NULL,
	[ReversalGLJournalId] [bigint] NULL,
	[CostTypeId] [bigint] NULL,
	[ProgressFundingId] [bigint] NULL,
	[AssetId] [bigint] NULL,
	[AssetFeatureId] [bigint] NULL,
	[PayableRemitToId] [bigint] NULL,
	[BlendedItemCodeId] [bigint] NULL,
	[PayableInvoiceId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[IsNewlyAdded] [bit] NOT NULL,
	[IsPrepaidUpfrontTax] [bit] NOT NULL,
	[InterestAccrualBalance_Amount] [decimal](16, 2) NOT NULL,
	[InterestAccrualBalance_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[OtherCostWithholdingTaxRate] [decimal](5, 2) NULL,
	[AssignOtherCostAtSKULevel] [bit] NOT NULL,
	[VATType] [nvarchar](7) COLLATE Latin1_General_CI_AS NULL,
	[SystemCalculated] [bit] NOT NULL,
	[TaxCodeId] [bigint] NULL,
	[TaxTypeId] [bigint] NULL,
	[TaxCodeRateId] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[PayableInvoiceOtherCosts]  WITH CHECK ADD  CONSTRAINT [EPayableInvoice_PayableInvoiceOtherCosts] FOREIGN KEY([PayableInvoiceId])
REFERENCES [dbo].[PayableInvoices] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[PayableInvoiceOtherCosts] CHECK CONSTRAINT [EPayableInvoice_PayableInvoiceOtherCosts]
GO
ALTER TABLE [dbo].[PayableInvoiceOtherCosts]  WITH CHECK ADD  CONSTRAINT [EPayableInvoiceOtherCost_Asset] FOREIGN KEY([AssetId])
REFERENCES [dbo].[Assets] ([Id])
GO
ALTER TABLE [dbo].[PayableInvoiceOtherCosts] CHECK CONSTRAINT [EPayableInvoiceOtherCost_Asset]
GO
ALTER TABLE [dbo].[PayableInvoiceOtherCosts]  WITH CHECK ADD  CONSTRAINT [EPayableInvoiceOtherCost_AssetFeature] FOREIGN KEY([AssetFeatureId])
REFERENCES [dbo].[AssetFeatures] ([Id])
GO
ALTER TABLE [dbo].[PayableInvoiceOtherCosts] CHECK CONSTRAINT [EPayableInvoiceOtherCost_AssetFeature]
GO
ALTER TABLE [dbo].[PayableInvoiceOtherCosts]  WITH CHECK ADD  CONSTRAINT [EPayableInvoiceOtherCost_BillTo] FOREIGN KEY([BillToId])
REFERENCES [dbo].[BillToes] ([Id])
GO
ALTER TABLE [dbo].[PayableInvoiceOtherCosts] CHECK CONSTRAINT [EPayableInvoiceOtherCost_BillTo]
GO
ALTER TABLE [dbo].[PayableInvoiceOtherCosts]  WITH CHECK ADD  CONSTRAINT [EPayableInvoiceOtherCost_BlendedItemCode] FOREIGN KEY([BlendedItemCodeId])
REFERENCES [dbo].[BlendedItemCodes] ([Id])
GO
ALTER TABLE [dbo].[PayableInvoiceOtherCosts] CHECK CONSTRAINT [EPayableInvoiceOtherCost_BlendedItemCode]
GO
ALTER TABLE [dbo].[PayableInvoiceOtherCosts]  WITH CHECK ADD  CONSTRAINT [EPayableInvoiceOtherCost_Contract] FOREIGN KEY([ContractId])
REFERENCES [dbo].[Contracts] ([Id])
GO
ALTER TABLE [dbo].[PayableInvoiceOtherCosts] CHECK CONSTRAINT [EPayableInvoiceOtherCost_Contract]
GO
ALTER TABLE [dbo].[PayableInvoiceOtherCosts]  WITH CHECK ADD  CONSTRAINT [EPayableInvoiceOtherCost_CostType] FOREIGN KEY([CostTypeId])
REFERENCES [dbo].[CostTypes] ([Id])
GO
ALTER TABLE [dbo].[PayableInvoiceOtherCosts] CHECK CONSTRAINT [EPayableInvoiceOtherCost_CostType]
GO
ALTER TABLE [dbo].[PayableInvoiceOtherCosts]  WITH CHECK ADD  CONSTRAINT [EPayableInvoiceOtherCost_GLJournal] FOREIGN KEY([GLJournalId])
REFERENCES [dbo].[GLJournals] ([Id])
GO
ALTER TABLE [dbo].[PayableInvoiceOtherCosts] CHECK CONSTRAINT [EPayableInvoiceOtherCost_GLJournal]
GO
ALTER TABLE [dbo].[PayableInvoiceOtherCosts]  WITH CHECK ADD  CONSTRAINT [EPayableInvoiceOtherCost_Location] FOREIGN KEY([LocationId])
REFERENCES [dbo].[Locations] ([Id])
GO
ALTER TABLE [dbo].[PayableInvoiceOtherCosts] CHECK CONSTRAINT [EPayableInvoiceOtherCost_Location]
GO
ALTER TABLE [dbo].[PayableInvoiceOtherCosts]  WITH CHECK ADD  CONSTRAINT [EPayableInvoiceOtherCost_OtherCostCode] FOREIGN KEY([OtherCostCodeId])
REFERENCES [dbo].[OtherCostCodes] ([Id])
GO
ALTER TABLE [dbo].[PayableInvoiceOtherCosts] CHECK CONSTRAINT [EPayableInvoiceOtherCost_OtherCostCode]
GO
ALTER TABLE [dbo].[PayableInvoiceOtherCosts]  WITH CHECK ADD  CONSTRAINT [EPayableInvoiceOtherCost_OtherCostPayableCode] FOREIGN KEY([OtherCostPayableCodeId])
REFERENCES [dbo].[PayableCodes] ([Id])
GO
ALTER TABLE [dbo].[PayableInvoiceOtherCosts] CHECK CONSTRAINT [EPayableInvoiceOtherCost_OtherCostPayableCode]
GO
ALTER TABLE [dbo].[PayableInvoiceOtherCosts]  WITH CHECK ADD  CONSTRAINT [EPayableInvoiceOtherCost_PayableRemitTo] FOREIGN KEY([PayableRemitToId])
REFERENCES [dbo].[RemitToes] ([Id])
GO
ALTER TABLE [dbo].[PayableInvoiceOtherCosts] CHECK CONSTRAINT [EPayableInvoiceOtherCost_PayableRemitTo]
GO
ALTER TABLE [dbo].[PayableInvoiceOtherCosts]  WITH CHECK ADD  CONSTRAINT [EPayableInvoiceOtherCost_ProgressFunding] FOREIGN KEY([ProgressFundingId])
REFERENCES [dbo].[PayableInvoiceOtherCosts] ([Id])
GO
ALTER TABLE [dbo].[PayableInvoiceOtherCosts] CHECK CONSTRAINT [EPayableInvoiceOtherCost_ProgressFunding]
GO
ALTER TABLE [dbo].[PayableInvoiceOtherCosts]  WITH CHECK ADD  CONSTRAINT [EPayableInvoiceOtherCost_ReceivableCode] FOREIGN KEY([ReceivableCodeId])
REFERENCES [dbo].[ReceivableCodes] ([Id])
GO
ALTER TABLE [dbo].[PayableInvoiceOtherCosts] CHECK CONSTRAINT [EPayableInvoiceOtherCost_ReceivableCode]
GO
ALTER TABLE [dbo].[PayableInvoiceOtherCosts]  WITH CHECK ADD  CONSTRAINT [EPayableInvoiceOtherCost_RemitTo] FOREIGN KEY([RemitToId])
REFERENCES [dbo].[RemitToes] ([Id])
GO
ALTER TABLE [dbo].[PayableInvoiceOtherCosts] CHECK CONSTRAINT [EPayableInvoiceOtherCost_RemitTo]
GO
ALTER TABLE [dbo].[PayableInvoiceOtherCosts]  WITH CHECK ADD  CONSTRAINT [EPayableInvoiceOtherCost_ReversalGLJournal] FOREIGN KEY([ReversalGLJournalId])
REFERENCES [dbo].[GLJournals] ([Id])
GO
ALTER TABLE [dbo].[PayableInvoiceOtherCosts] CHECK CONSTRAINT [EPayableInvoiceOtherCost_ReversalGLJournal]
GO
ALTER TABLE [dbo].[PayableInvoiceOtherCosts]  WITH CHECK ADD  CONSTRAINT [EPayableInvoiceOtherCost_SundryReceivable] FOREIGN KEY([SundryReceivableId])
REFERENCES [dbo].[Sundries] ([Id])
GO
ALTER TABLE [dbo].[PayableInvoiceOtherCosts] CHECK CONSTRAINT [EPayableInvoiceOtherCost_SundryReceivable]
GO
ALTER TABLE [dbo].[PayableInvoiceOtherCosts]  WITH CHECK ADD  CONSTRAINT [EPayableInvoiceOtherCost_TaxCode] FOREIGN KEY([TaxCodeId])
REFERENCES [dbo].[TaxCodes] ([Id])
GO
ALTER TABLE [dbo].[PayableInvoiceOtherCosts] CHECK CONSTRAINT [EPayableInvoiceOtherCost_TaxCode]
GO
ALTER TABLE [dbo].[PayableInvoiceOtherCosts]  WITH CHECK ADD  CONSTRAINT [EPayableInvoiceOtherCost_TaxCodeRate] FOREIGN KEY([TaxCodeRateId])
REFERENCES [dbo].[TaxCodeRates] ([Id])
GO
ALTER TABLE [dbo].[PayableInvoiceOtherCosts] CHECK CONSTRAINT [EPayableInvoiceOtherCost_TaxCodeRate]
GO
ALTER TABLE [dbo].[PayableInvoiceOtherCosts]  WITH CHECK ADD  CONSTRAINT [EPayableInvoiceOtherCost_TaxType] FOREIGN KEY([TaxTypeId])
REFERENCES [dbo].[TaxTypes] ([Id])
GO
ALTER TABLE [dbo].[PayableInvoiceOtherCosts] CHECK CONSTRAINT [EPayableInvoiceOtherCost_TaxType]
GO
ALTER TABLE [dbo].[PayableInvoiceOtherCosts]  WITH CHECK ADD  CONSTRAINT [EPayableInvoiceOtherCost_Vendor] FOREIGN KEY([VendorId])
REFERENCES [dbo].[Vendors] ([Id])
GO
ALTER TABLE [dbo].[PayableInvoiceOtherCosts] CHECK CONSTRAINT [EPayableInvoiceOtherCost_Vendor]
GO
