SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LateFeeReceivables](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[EntityType] [nvarchar](8) COLLATE Latin1_General_CI_AS NOT NULL,
	[DueDate] [date] NOT NULL,
	[StartDate] [date] NULL,
	[EndDate] [date] NULL,
	[DaysLate] [int] NULL,
	[InvoiceReceivableGroupingOption] [nvarchar](8) COLLATE Latin1_General_CI_AS NOT NULL,
	[Amount_Amount] [decimal](16, 2) NOT NULL,
	[Amount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[ReceivableAmendmentType] [nvarchar](20) COLLATE Latin1_General_CI_AS NOT NULL,
	[EntityId] [bigint] NOT NULL,
	[InvoiceComment] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[AccountingTreatment] [nvarchar](12) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[IsManuallyAssessed] [bit] NOT NULL,
	[ReversedDate] [date] NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[LegalEntityId] [bigint] NULL,
	[CurrencyId] [bigint] NULL,
	[BillToId] [bigint] NOT NULL,
	[RemitToId] [bigint] NOT NULL,
	[ReceivableCodeId] [bigint] NOT NULL,
	[ReceivableInvoiceId] [bigint] NULL,
	[InstrumentTypeId] [bigint] NULL,
	[LineofBusinessId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[ReceiptId] [bigint] NULL,
	[CostCenterId] [bigint] NOT NULL,
	[IsServiced] [bit] NOT NULL,
	[IsCollected] [bit] NOT NULL,
	[IsPrivateLabel] [bit] NOT NULL,
	[IsOwned] [bit] NOT NULL,
	[TaxBasisAmount_Amount] [decimal](16, 2) NOT NULL,
	[TaxBasisAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[LateFeeReceivables]  WITH CHECK ADD  CONSTRAINT [ELateFeeReceivable_BillTo] FOREIGN KEY([BillToId])
REFERENCES [dbo].[BillToes] ([Id])
GO
ALTER TABLE [dbo].[LateFeeReceivables] CHECK CONSTRAINT [ELateFeeReceivable_BillTo]
GO
ALTER TABLE [dbo].[LateFeeReceivables]  WITH CHECK ADD  CONSTRAINT [ELateFeeReceivable_CostCenter] FOREIGN KEY([CostCenterId])
REFERENCES [dbo].[CostCenterConfigs] ([Id])
GO
ALTER TABLE [dbo].[LateFeeReceivables] CHECK CONSTRAINT [ELateFeeReceivable_CostCenter]
GO
ALTER TABLE [dbo].[LateFeeReceivables]  WITH CHECK ADD  CONSTRAINT [ELateFeeReceivable_Currency] FOREIGN KEY([CurrencyId])
REFERENCES [dbo].[Currencies] ([Id])
GO
ALTER TABLE [dbo].[LateFeeReceivables] CHECK CONSTRAINT [ELateFeeReceivable_Currency]
GO
ALTER TABLE [dbo].[LateFeeReceivables]  WITH CHECK ADD  CONSTRAINT [ELateFeeReceivable_InstrumentType] FOREIGN KEY([InstrumentTypeId])
REFERENCES [dbo].[InstrumentTypes] ([Id])
GO
ALTER TABLE [dbo].[LateFeeReceivables] CHECK CONSTRAINT [ELateFeeReceivable_InstrumentType]
GO
ALTER TABLE [dbo].[LateFeeReceivables]  WITH CHECK ADD  CONSTRAINT [ELateFeeReceivable_LegalEntity] FOREIGN KEY([LegalEntityId])
REFERENCES [dbo].[LegalEntities] ([Id])
GO
ALTER TABLE [dbo].[LateFeeReceivables] CHECK CONSTRAINT [ELateFeeReceivable_LegalEntity]
GO
ALTER TABLE [dbo].[LateFeeReceivables]  WITH CHECK ADD  CONSTRAINT [ELateFeeReceivable_LineofBusiness] FOREIGN KEY([LineofBusinessId])
REFERENCES [dbo].[LineofBusinesses] ([Id])
GO
ALTER TABLE [dbo].[LateFeeReceivables] CHECK CONSTRAINT [ELateFeeReceivable_LineofBusiness]
GO
ALTER TABLE [dbo].[LateFeeReceivables]  WITH CHECK ADD  CONSTRAINT [ELateFeeReceivable_Receipt] FOREIGN KEY([ReceiptId])
REFERENCES [dbo].[Receipts] ([Id])
GO
ALTER TABLE [dbo].[LateFeeReceivables] CHECK CONSTRAINT [ELateFeeReceivable_Receipt]
GO
ALTER TABLE [dbo].[LateFeeReceivables]  WITH CHECK ADD  CONSTRAINT [ELateFeeReceivable_ReceivableCode] FOREIGN KEY([ReceivableCodeId])
REFERENCES [dbo].[ReceivableCodes] ([Id])
GO
ALTER TABLE [dbo].[LateFeeReceivables] CHECK CONSTRAINT [ELateFeeReceivable_ReceivableCode]
GO
ALTER TABLE [dbo].[LateFeeReceivables]  WITH CHECK ADD  CONSTRAINT [ELateFeeReceivable_ReceivableInvoice] FOREIGN KEY([ReceivableInvoiceId])
REFERENCES [dbo].[ReceivableInvoices] ([Id])
GO
ALTER TABLE [dbo].[LateFeeReceivables] CHECK CONSTRAINT [ELateFeeReceivable_ReceivableInvoice]
GO
ALTER TABLE [dbo].[LateFeeReceivables]  WITH CHECK ADD  CONSTRAINT [ELateFeeReceivable_RemitTo] FOREIGN KEY([RemitToId])
REFERENCES [dbo].[RemitToes] ([Id])
GO
ALTER TABLE [dbo].[LateFeeReceivables] CHECK CONSTRAINT [ELateFeeReceivable_RemitTo]
GO
