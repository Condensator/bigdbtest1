SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LeaseAmendments](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[LeaseAmendmentStatus] [nvarchar](9) COLLATE Latin1_General_CI_AS NULL,
	[ReceivableAmendmentType] [nvarchar](20) COLLATE Latin1_General_CI_AS NULL,
	[AmendmentType] [nvarchar](31) COLLATE Latin1_General_CI_AS NULL,
	[AmendmentDate] [date] NULL,
	[Description] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[AmendmentAtInception] [bit] NOT NULL,
	[IsTDR] [bit] NOT NULL,
	[TDRReason] [nvarchar](24) COLLATE Latin1_General_CI_AS NULL,
	[PreRestructureLessorYield] [decimal](12, 6) NOT NULL,
	[PreRestructureClassificationYield] [decimal](12, 6) NOT NULL,
	[FinalAcceptanceDate] [date] NULL,
	[IsLienFilingRequired] [bit] NOT NULL,
	[IsLienFilingException] [bit] NOT NULL,
	[LienExceptionComment] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[PreRestructureLeaseNBV_Amount] [decimal](16, 2) NOT NULL,
	[PreRestructureLeaseNBV_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[PostRestructureLeaseNBV_Amount] [decimal](16, 2) NOT NULL,
	[PostRestructureLeaseNBV_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[PreRestructureResidualBooked_Amount] [decimal](16, 2) NOT NULL,
	[PreRestructureResidualBooked_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[PostRestructureResidualBooked_Amount] [decimal](16, 2) NOT NULL,
	[PostRestructureResidualBooked_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[PreRestructureFAS91Balance_Amount] [decimal](16, 2) NOT NULL,
	[PreRestructureFAS91Balance_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[PostRestructureFAS91Balance_Amount] [decimal](16, 2) NOT NULL,
	[PostRestructureFAS91Balance_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[NetWritedowns_Amount] [decimal](16, 2) NOT NULL,
	[NetWritedowns_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[AccountingDate] [date] NULL,
	[PostDate] [date] NULL,
	[ImpairmentAmount_Amount] [decimal](16, 2) NULL,
	[ImpairmentAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[IsLeaseLevelImpairment] [bit] NOT NULL,
	[AccumulatedImpairmentAmount_Amount] [decimal](16, 2) NULL,
	[AccumulatedImpairmentAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[PreRestructureUnguaranteedResidual_Amount] [decimal](16, 2) NOT NULL,
	[PreRestructureUnguaranteedResidual_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[PostRestructureUnguaranteedResidual_Amount] [decimal](16, 2) NOT NULL,
	[PostRestructureUnguaranteedResidual_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[InvoiceComment] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[SalesTaxRemittanceMethod] [nvarchar](12) COLLATE Latin1_General_CI_AS NULL,
	[LienExceptionReason] [nvarchar](24) COLLATE Latin1_General_CI_AS NULL,
	[LeaseSequenceNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[LeaseAlias] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[PaymentDate] [date] NULL,
	[TaxPaidtoVendor_Amount] [decimal](16, 2) NOT NULL,
	[TaxPaidtoVendor_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[GSTTaxPaidtoVendor_Amount] [decimal](16, 2) NOT NULL,
	[GSTTaxPaidtoVendor_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[HSTTaxPaidtoVendor_Amount] [decimal](16, 2) NOT NULL,
	[HSTTaxPaidtoVendor_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[QSTorPSTTaxPaidtoVendor_Amount] [decimal](16, 2) NOT NULL,
	[QSTorPSTTaxPaidtoVendor_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[CurrentLeaseFinanceId] [bigint] NULL,
	[LeasePaymentScheduleId] [bigint] NULL,
	[DealProductTypeId] [bigint] NULL,
	[GLTemplateId] [bigint] NULL,
	[BillToId] [bigint] NULL,
	[RemitToId] [bigint] NULL,
	[PayOffGLTemplateId] [bigint] NULL,
	[OriginalLeaseFinanceId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[DealTypeId] [bigint] NULL,
	[OriginalDealProductTypeId] [bigint] NULL,
	[PreRestructureLessorYieldLeaseAsset] [decimal](12, 6) NOT NULL,
	[PreRestructureLessorYieldFinanceAsset] [decimal](12, 6) NOT NULL,
	[PreRestructureClassificationYield5A] [decimal](12, 6) NOT NULL,
	[PreRestructureClassificationYield5B] [decimal](12, 6) NOT NULL,
	[FloatRateRestructure] [bit] NOT NULL,
	[AmendmentReasonId] [bigint] NULL,
	[AmendmentReasonComment] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[CreateCPURestructure] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[LeaseAmendments]  WITH CHECK ADD  CONSTRAINT [ELeaseAmendment_AmendmentReason] FOREIGN KEY([AmendmentReasonId])
REFERENCES [dbo].[ContractAmendmentReasonCodes] ([Id])
GO
ALTER TABLE [dbo].[LeaseAmendments] CHECK CONSTRAINT [ELeaseAmendment_AmendmentReason]
GO
ALTER TABLE [dbo].[LeaseAmendments]  WITH CHECK ADD  CONSTRAINT [ELeaseAmendment_BillTo] FOREIGN KEY([BillToId])
REFERENCES [dbo].[BillToes] ([Id])
GO
ALTER TABLE [dbo].[LeaseAmendments] CHECK CONSTRAINT [ELeaseAmendment_BillTo]
GO
ALTER TABLE [dbo].[LeaseAmendments]  WITH CHECK ADD  CONSTRAINT [ELeaseAmendment_CurrentLeaseFinance] FOREIGN KEY([CurrentLeaseFinanceId])
REFERENCES [dbo].[LeaseFinances] ([Id])
GO
ALTER TABLE [dbo].[LeaseAmendments] CHECK CONSTRAINT [ELeaseAmendment_CurrentLeaseFinance]
GO
ALTER TABLE [dbo].[LeaseAmendments]  WITH CHECK ADD  CONSTRAINT [ELeaseAmendment_DealProductType] FOREIGN KEY([DealProductTypeId])
REFERENCES [dbo].[DealProductTypes] ([Id])
GO
ALTER TABLE [dbo].[LeaseAmendments] CHECK CONSTRAINT [ELeaseAmendment_DealProductType]
GO
ALTER TABLE [dbo].[LeaseAmendments]  WITH CHECK ADD  CONSTRAINT [ELeaseAmendment_DealType] FOREIGN KEY([DealTypeId])
REFERENCES [dbo].[DealTypes] ([Id])
GO
ALTER TABLE [dbo].[LeaseAmendments] CHECK CONSTRAINT [ELeaseAmendment_DealType]
GO
ALTER TABLE [dbo].[LeaseAmendments]  WITH CHECK ADD  CONSTRAINT [ELeaseAmendment_GLTemplate] FOREIGN KEY([GLTemplateId])
REFERENCES [dbo].[GLTemplates] ([Id])
GO
ALTER TABLE [dbo].[LeaseAmendments] CHECK CONSTRAINT [ELeaseAmendment_GLTemplate]
GO
ALTER TABLE [dbo].[LeaseAmendments]  WITH CHECK ADD  CONSTRAINT [ELeaseAmendment_LeasePaymentSchedule] FOREIGN KEY([LeasePaymentScheduleId])
REFERENCES [dbo].[LeasePaymentSchedules] ([Id])
GO
ALTER TABLE [dbo].[LeaseAmendments] CHECK CONSTRAINT [ELeaseAmendment_LeasePaymentSchedule]
GO
ALTER TABLE [dbo].[LeaseAmendments]  WITH CHECK ADD  CONSTRAINT [ELeaseAmendment_OriginalDealProductType] FOREIGN KEY([OriginalDealProductTypeId])
REFERENCES [dbo].[DealProductTypes] ([Id])
GO
ALTER TABLE [dbo].[LeaseAmendments] CHECK CONSTRAINT [ELeaseAmendment_OriginalDealProductType]
GO
ALTER TABLE [dbo].[LeaseAmendments]  WITH CHECK ADD  CONSTRAINT [ELeaseAmendment_OriginalLeaseFinance] FOREIGN KEY([OriginalLeaseFinanceId])
REFERENCES [dbo].[LeaseFinances] ([Id])
GO
ALTER TABLE [dbo].[LeaseAmendments] CHECK CONSTRAINT [ELeaseAmendment_OriginalLeaseFinance]
GO
ALTER TABLE [dbo].[LeaseAmendments]  WITH CHECK ADD  CONSTRAINT [ELeaseAmendment_PayOffGLTemplate] FOREIGN KEY([PayOffGLTemplateId])
REFERENCES [dbo].[GLTemplates] ([Id])
GO
ALTER TABLE [dbo].[LeaseAmendments] CHECK CONSTRAINT [ELeaseAmendment_PayOffGLTemplate]
GO
ALTER TABLE [dbo].[LeaseAmendments]  WITH CHECK ADD  CONSTRAINT [ELeaseAmendment_RemitTo] FOREIGN KEY([RemitToId])
REFERENCES [dbo].[RemitToes] ([Id])
GO
ALTER TABLE [dbo].[LeaseAmendments] CHECK CONSTRAINT [ELeaseAmendment_RemitTo]
GO
