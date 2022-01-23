SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ReceivableForTransfers](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Number] [bigint] NULL,
	[Alias] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[ContractType] [nvarchar](14) COLLATE Latin1_General_CI_AS NOT NULL,
	[ReceivableForTransferType] [nvarchar](16) COLLATE Latin1_General_CI_AS NOT NULL,
	[ApprovalStatus] [nvarchar](25) COLLATE Latin1_General_CI_AS NOT NULL,
	[Comment] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[RetainedPercentage] [decimal](18, 8) NULL,
	[IsCalculateRate] [bit] NOT NULL,
	[DiscountRate] [decimal](7, 4) NULL,
	[DayCountConvention] [nvarchar](14) COLLATE Latin1_General_CI_AS NULL,
	[PostDate] [date] NULL,
	[AccountingDate] [date] NULL,
	[ActualProceeds_Amount] [decimal](16, 2) NULL,
	[ActualProceeds_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[IsPricingPerformed] [bit] NOT NULL,
	[SecurityDeposit_Amount] [decimal](16, 2) NULL,
	[SecurityDeposit_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[IsPricingParametersChanged] [bit] NOT NULL,
	[IsFromContract] [bit] NOT NULL,
	[IsBlendedItemParametersChanged] [bit] NOT NULL,
	[SoldNBV_Amount] [decimal](16, 2) NULL,
	[SoldNBV_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[TotalNBV_Amount] [decimal](16, 2) NULL,
	[TotalNBV_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[LegalEntityId] [bigint] NULL,
	[RemitToId] [bigint] NULL,
	[ContractId] [bigint] NOT NULL,
	[LeasePaymentId] [bigint] NULL,
	[LoanPaymentId] [bigint] NULL,
	[ProceedsReceivableCodeId] [bigint] NULL,
	[RentalProceedsPayableCodeId] [bigint] NULL,
	[ScrapeReceivableCodeId] [bigint] NULL,
	[SyndicationGLTemplateId] [bigint] NULL,
	[UpfrontSyndicationFeeCodeId] [bigint] NULL,
	[ReceiptGLTemplateId] [bigint] NULL,
	[LeaseFinanceId] [bigint] NULL,
	[LoanFinanceId] [bigint] NULL,
	[SyndicationGLJournalId] [bigint] NULL,
	[OldProceedsReceivableCodeId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[SoldInterestAccrued_Amount] [decimal](16, 2) NOT NULL,
	[SoldInterestAccrued_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[EffectiveDate] [date] NULL,
	[FundingDate] [date] NULL,
	[TaxDepDisposalTemplateId] [bigint] NULL,
	[IsCalculatePercentage] [bit] NOT NULL,
	[Name] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[FinancingTotalNBV_Amount] [decimal](16, 2) NULL,
	[FinancingTotalNBV_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[FinancingSoldNBV_Amount] [decimal](16, 2) NULL,
	[FinancingSoldNBV_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[RentalProceedsWithholdingTaxRate] [decimal](5, 2) NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ReceivableForTransfers]  WITH CHECK ADD  CONSTRAINT [EReceivableForTransfer_Contract] FOREIGN KEY([ContractId])
REFERENCES [dbo].[Contracts] ([Id])
GO
ALTER TABLE [dbo].[ReceivableForTransfers] CHECK CONSTRAINT [EReceivableForTransfer_Contract]
GO
ALTER TABLE [dbo].[ReceivableForTransfers]  WITH CHECK ADD  CONSTRAINT [EReceivableForTransfer_LeaseFinance] FOREIGN KEY([LeaseFinanceId])
REFERENCES [dbo].[LeaseFinances] ([Id])
GO
ALTER TABLE [dbo].[ReceivableForTransfers] CHECK CONSTRAINT [EReceivableForTransfer_LeaseFinance]
GO
ALTER TABLE [dbo].[ReceivableForTransfers]  WITH CHECK ADD  CONSTRAINT [EReceivableForTransfer_LeasePayment] FOREIGN KEY([LeasePaymentId])
REFERENCES [dbo].[LeasePaymentSchedules] ([Id])
GO
ALTER TABLE [dbo].[ReceivableForTransfers] CHECK CONSTRAINT [EReceivableForTransfer_LeasePayment]
GO
ALTER TABLE [dbo].[ReceivableForTransfers]  WITH CHECK ADD  CONSTRAINT [EReceivableForTransfer_LegalEntity] FOREIGN KEY([LegalEntityId])
REFERENCES [dbo].[LegalEntities] ([Id])
GO
ALTER TABLE [dbo].[ReceivableForTransfers] CHECK CONSTRAINT [EReceivableForTransfer_LegalEntity]
GO
ALTER TABLE [dbo].[ReceivableForTransfers]  WITH CHECK ADD  CONSTRAINT [EReceivableForTransfer_LoanFinance] FOREIGN KEY([LoanFinanceId])
REFERENCES [dbo].[LoanFinances] ([Id])
GO
ALTER TABLE [dbo].[ReceivableForTransfers] CHECK CONSTRAINT [EReceivableForTransfer_LoanFinance]
GO
ALTER TABLE [dbo].[ReceivableForTransfers]  WITH CHECK ADD  CONSTRAINT [EReceivableForTransfer_LoanPayment] FOREIGN KEY([LoanPaymentId])
REFERENCES [dbo].[LoanPaymentSchedules] ([Id])
GO
ALTER TABLE [dbo].[ReceivableForTransfers] CHECK CONSTRAINT [EReceivableForTransfer_LoanPayment]
GO
ALTER TABLE [dbo].[ReceivableForTransfers]  WITH CHECK ADD  CONSTRAINT [EReceivableForTransfer_OldProceedsReceivableCode] FOREIGN KEY([OldProceedsReceivableCodeId])
REFERENCES [dbo].[ReceivableCodes] ([Id])
GO
ALTER TABLE [dbo].[ReceivableForTransfers] CHECK CONSTRAINT [EReceivableForTransfer_OldProceedsReceivableCode]
GO
ALTER TABLE [dbo].[ReceivableForTransfers]  WITH CHECK ADD  CONSTRAINT [EReceivableForTransfer_ProceedsReceivableCode] FOREIGN KEY([ProceedsReceivableCodeId])
REFERENCES [dbo].[ReceivableCodes] ([Id])
GO
ALTER TABLE [dbo].[ReceivableForTransfers] CHECK CONSTRAINT [EReceivableForTransfer_ProceedsReceivableCode]
GO
ALTER TABLE [dbo].[ReceivableForTransfers]  WITH CHECK ADD  CONSTRAINT [EReceivableForTransfer_ReceiptGLTemplate] FOREIGN KEY([ReceiptGLTemplateId])
REFERENCES [dbo].[GLTemplates] ([Id])
GO
ALTER TABLE [dbo].[ReceivableForTransfers] CHECK CONSTRAINT [EReceivableForTransfer_ReceiptGLTemplate]
GO
ALTER TABLE [dbo].[ReceivableForTransfers]  WITH CHECK ADD  CONSTRAINT [EReceivableForTransfer_RemitTo] FOREIGN KEY([RemitToId])
REFERENCES [dbo].[RemitToes] ([Id])
GO
ALTER TABLE [dbo].[ReceivableForTransfers] CHECK CONSTRAINT [EReceivableForTransfer_RemitTo]
GO
ALTER TABLE [dbo].[ReceivableForTransfers]  WITH CHECK ADD  CONSTRAINT [EReceivableForTransfer_RentalProceedsPayableCode] FOREIGN KEY([RentalProceedsPayableCodeId])
REFERENCES [dbo].[PayableCodes] ([Id])
GO
ALTER TABLE [dbo].[ReceivableForTransfers] CHECK CONSTRAINT [EReceivableForTransfer_RentalProceedsPayableCode]
GO
ALTER TABLE [dbo].[ReceivableForTransfers]  WITH CHECK ADD  CONSTRAINT [EReceivableForTransfer_ScrapeReceivableCode] FOREIGN KEY([ScrapeReceivableCodeId])
REFERENCES [dbo].[ReceivableCodes] ([Id])
GO
ALTER TABLE [dbo].[ReceivableForTransfers] CHECK CONSTRAINT [EReceivableForTransfer_ScrapeReceivableCode]
GO
ALTER TABLE [dbo].[ReceivableForTransfers]  WITH CHECK ADD  CONSTRAINT [EReceivableForTransfer_SyndicationGLJournal] FOREIGN KEY([SyndicationGLJournalId])
REFERENCES [dbo].[GLJournals] ([Id])
GO
ALTER TABLE [dbo].[ReceivableForTransfers] CHECK CONSTRAINT [EReceivableForTransfer_SyndicationGLJournal]
GO
ALTER TABLE [dbo].[ReceivableForTransfers]  WITH CHECK ADD  CONSTRAINT [EReceivableForTransfer_SyndicationGLTemplate] FOREIGN KEY([SyndicationGLTemplateId])
REFERENCES [dbo].[GLTemplates] ([Id])
GO
ALTER TABLE [dbo].[ReceivableForTransfers] CHECK CONSTRAINT [EReceivableForTransfer_SyndicationGLTemplate]
GO
ALTER TABLE [dbo].[ReceivableForTransfers]  WITH CHECK ADD  CONSTRAINT [EReceivableForTransfer_TaxDepDisposalTemplate] FOREIGN KEY([TaxDepDisposalTemplateId])
REFERENCES [dbo].[GLTemplates] ([Id])
GO
ALTER TABLE [dbo].[ReceivableForTransfers] CHECK CONSTRAINT [EReceivableForTransfer_TaxDepDisposalTemplate]
GO
ALTER TABLE [dbo].[ReceivableForTransfers]  WITH CHECK ADD  CONSTRAINT [EReceivableForTransfer_UpfrontSyndicationFeeCode] FOREIGN KEY([UpfrontSyndicationFeeCodeId])
REFERENCES [dbo].[BlendedItemCodes] ([Id])
GO
ALTER TABLE [dbo].[ReceivableForTransfers] CHECK CONSTRAINT [EReceivableForTransfer_UpfrontSyndicationFeeCode]
GO
