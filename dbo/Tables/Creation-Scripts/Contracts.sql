SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Contracts](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[SequenceNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[Alias] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[ReferenceType] [nvarchar](15) COLLATE Latin1_General_CI_AS NULL,
	[ContractType] [nvarchar](14) COLLATE Latin1_General_CI_AS NULL,
	[DiscountForLoanStatus] [nvarchar](10) COLLATE Latin1_General_CI_AS NULL,
	[SyndicationType] [nvarchar](16) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsSyndictaionGeneratePayable] [bit] NOT NULL,
	[IsLienFilingRequired] [bit] NOT NULL,
	[IsLienFilingException] [bit] NOT NULL,
	[LienExceptionComment] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[LienExceptionReason] [nvarchar](24) COLLATE Latin1_General_CI_AS NULL,
	[IsConfidential] [bit] NOT NULL,
	[ReceivableAmendmentType] [nvarchar](20) COLLATE Latin1_General_CI_AS NULL,
	[InvoiceComment] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[ChargeOffStatus] [nvarchar](10) COLLATE Latin1_General_CI_AS NULL,
	[OriginalBookingDate] [date] NULL,
	[FinalAcceptanceDate] [date] NULL,
	[SalesTaxRemittanceMethod] [nvarchar](12) COLLATE Latin1_General_CI_AS NULL,
	[LastPaymentAmount_Amount] [decimal](16, 2) NULL,
	[LastPaymentAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[LastPaymentDate] [date] NULL,
	[TaxPaidtoVendor_Amount] [decimal](16, 2) NULL,
	[TaxPaidtoVendor_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[GSTTaxPaidtoVendor_Amount] [decimal](16, 2) NULL,
	[GSTTaxPaidtoVendor_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[HSTTaxPaidtoVendor_Amount] [decimal](16, 2) NULL,
	[HSTTaxPaidtoVendor_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[QSTorPSTTaxPaidtoVendor_Amount] [decimal](16, 2) NULL,
	[QSTorPSTTaxPaidtoVendor_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[IsNonAccrual] [bit] NOT NULL,
	[NonAccrualDate] [date] NULL,
	[Status] [nvarchar](16) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsOnHold] [bit] NOT NULL,
	[IsAssignToRecovery] [bit] NOT NULL,
	[ReportStatus] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[CurrencyId] [bigint] NOT NULL,
	[BillToId] [bigint] NULL,
	[RemitToId] [bigint] NULL,
	[DealProductTypeId] [bigint] NULL,
	[LineofBusinessId] [bigint] NOT NULL,
	[CreditApprovedStructureId] [bigint] NULL,
	[ReceiptHierarchyTemplateId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[IsPostScratchIndicator] [bit] NOT NULL,
	[PreviousScheduleNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[ExternalReferenceNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[IsReportableDelinquency] [bit] NOT NULL,
	[InterimLoanAndSecurityAgreementDate] [date] NULL,
	[u_ConversionSource] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[DecisionComments] [nvarchar](2500) COLLATE Latin1_General_CI_AS NULL,
	[DealTypeId] [bigint] NULL,
	[CostCenterId] [bigint] NOT NULL,
	[ProductAndServiceTypeConfigId] [bigint] NULL,
	[ProgramIndicatorConfigId] [bigint] NULL,
	[DocumentMethod] [nvarchar](14) COLLATE Latin1_General_CI_AS NULL,
	[FirstRightOfRefusal] [nvarchar](17) COLLATE Latin1_General_CI_AS NULL,
	[LanguageId] [bigint] NULL,
	[IsNonAccrualExempt] [bit] NOT NULL,
	[TaxAssessmentLevel] [nvarchar](8) COLLATE Latin1_General_CI_AS NULL,
	[ServicingRole] [nvarchar](14) COLLATE Latin1_General_CI_AS NULL,
	[AccountingStandard] [nvarchar](12) COLLATE Latin1_General_CI_AS NULL,
	[DiscountingSharedPercentage] [decimal](5, 2) NULL,
	[FollowOldDueDayMethod] [bit] NOT NULL,
	[CountryId] [bigint] NULL,
	[DoubtfulCollectability] [bit] NOT NULL,
	[VehicleLeaseType] [nvarchar](9) COLLATE Latin1_General_CI_AS NULL,
	[BackgroundProcessingPending] [bit] NOT NULL,
	[OpportunityNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[Contracts]  WITH CHECK ADD  CONSTRAINT [EContract_BillTo] FOREIGN KEY([BillToId])
REFERENCES [dbo].[BillToes] ([Id])
GO
ALTER TABLE [dbo].[Contracts] CHECK CONSTRAINT [EContract_BillTo]
GO
ALTER TABLE [dbo].[Contracts]  WITH CHECK ADD  CONSTRAINT [EContract_CostCenter] FOREIGN KEY([CostCenterId])
REFERENCES [dbo].[CostCenterConfigs] ([Id])
GO
ALTER TABLE [dbo].[Contracts] CHECK CONSTRAINT [EContract_CostCenter]
GO
ALTER TABLE [dbo].[Contracts]  WITH CHECK ADD  CONSTRAINT [EContract_Country] FOREIGN KEY([CountryId])
REFERENCES [dbo].[Countries] ([Id])
GO
ALTER TABLE [dbo].[Contracts] CHECK CONSTRAINT [EContract_Country]
GO
ALTER TABLE [dbo].[Contracts]  WITH CHECK ADD  CONSTRAINT [EContract_CreditApprovedStructure] FOREIGN KEY([CreditApprovedStructureId])
REFERENCES [dbo].[CreditApprovedStructures] ([Id])
GO
ALTER TABLE [dbo].[Contracts] CHECK CONSTRAINT [EContract_CreditApprovedStructure]
GO
ALTER TABLE [dbo].[Contracts]  WITH CHECK ADD  CONSTRAINT [EContract_Currency] FOREIGN KEY([CurrencyId])
REFERENCES [dbo].[Currencies] ([Id])
GO
ALTER TABLE [dbo].[Contracts] CHECK CONSTRAINT [EContract_Currency]
GO
ALTER TABLE [dbo].[Contracts]  WITH CHECK ADD  CONSTRAINT [EContract_DealProductType] FOREIGN KEY([DealProductTypeId])
REFERENCES [dbo].[DealProductTypes] ([Id])
GO
ALTER TABLE [dbo].[Contracts] CHECK CONSTRAINT [EContract_DealProductType]
GO
ALTER TABLE [dbo].[Contracts]  WITH CHECK ADD  CONSTRAINT [EContract_DealType] FOREIGN KEY([DealTypeId])
REFERENCES [dbo].[DealTypes] ([Id])
GO
ALTER TABLE [dbo].[Contracts] CHECK CONSTRAINT [EContract_DealType]
GO
ALTER TABLE [dbo].[Contracts]  WITH CHECK ADD  CONSTRAINT [EContract_Language] FOREIGN KEY([LanguageId])
REFERENCES [dbo].[LanguageConfigs] ([Id])
GO
ALTER TABLE [dbo].[Contracts] CHECK CONSTRAINT [EContract_Language]
GO
ALTER TABLE [dbo].[Contracts]  WITH CHECK ADD  CONSTRAINT [EContract_LineofBusiness] FOREIGN KEY([LineofBusinessId])
REFERENCES [dbo].[LineofBusinesses] ([Id])
GO
ALTER TABLE [dbo].[Contracts] CHECK CONSTRAINT [EContract_LineofBusiness]
GO
ALTER TABLE [dbo].[Contracts]  WITH CHECK ADD  CONSTRAINT [EContract_ProductAndServiceTypeConfig] FOREIGN KEY([ProductAndServiceTypeConfigId])
REFERENCES [dbo].[ProductAndServiceTypeConfigs] ([Id])
GO
ALTER TABLE [dbo].[Contracts] CHECK CONSTRAINT [EContract_ProductAndServiceTypeConfig]
GO
ALTER TABLE [dbo].[Contracts]  WITH CHECK ADD  CONSTRAINT [EContract_ProgramIndicatorConfig] FOREIGN KEY([ProgramIndicatorConfigId])
REFERENCES [dbo].[ProgramIndicatorConfigs] ([Id])
GO
ALTER TABLE [dbo].[Contracts] CHECK CONSTRAINT [EContract_ProgramIndicatorConfig]
GO
ALTER TABLE [dbo].[Contracts]  WITH CHECK ADD  CONSTRAINT [EContract_ReceiptHierarchyTemplate] FOREIGN KEY([ReceiptHierarchyTemplateId])
REFERENCES [dbo].[ReceiptHierarchyTemplates] ([Id])
GO
ALTER TABLE [dbo].[Contracts] CHECK CONSTRAINT [EContract_ReceiptHierarchyTemplate]
GO
ALTER TABLE [dbo].[Contracts]  WITH CHECK ADD  CONSTRAINT [EContract_RemitTo] FOREIGN KEY([RemitToId])
REFERENCES [dbo].[RemitToes] ([Id])
GO
ALTER TABLE [dbo].[Contracts] CHECK CONSTRAINT [EContract_RemitTo]
GO
