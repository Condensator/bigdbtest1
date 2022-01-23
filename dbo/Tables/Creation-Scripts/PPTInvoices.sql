SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PPTInvoices](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[PPTInvoiceNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[TaxBillType] [nvarchar](20) COLLATE Latin1_General_CI_AS NOT NULL,
	[DiscountDueDate] [date] NULL,
	[InvoiceDate] [date] NOT NULL,
	[BatchNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[PayableCodeDescription] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[PPTTaxBase_Amount] [decimal](16, 2) NOT NULL,
	[PPTTaxBase_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[PPTInterest_Amount] [decimal](16, 2) NOT NULL,
	[PPTInterest_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[PPTPenalty_Amount] [decimal](16, 2) NOT NULL,
	[PPTPenalty_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[PPTLienFees_Amount] [decimal](16, 2) NOT NULL,
	[PPTLienFees_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[PPTAdministartionFees_Amount] [decimal](16, 2) NOT NULL,
	[PPTAdministartionFees_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[PPTUnbilledWriteOff_Amount] [decimal](16, 2) NOT NULL,
	[PPTUnbilledWriteOff_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[PPTEarlyPaymentDiscount_Amount] [decimal](16, 2) NOT NULL,
	[PPTEarlyPaymentDiscount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[TotalPPTPayableAmount_Amount] [decimal](16, 2) NOT NULL,
	[TotalPPTPayableAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[Type] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[LienDate] [date] NOT NULL,
	[TaxYear] [int] NOT NULL,
	[TaxEntity] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[ReceivedDate] [date] NOT NULL,
	[DueDate] [date] NOT NULL,
	[FollowUpDate] [date] NOT NULL,
	[ParcelNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[AccountNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[TotalAssessed_Amount] [decimal](16, 2) NOT NULL,
	[TotalAssessed_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[RenderedValue_Amount] [decimal](16, 2) NOT NULL,
	[RenderedValue_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[RenderedValueDifference] [decimal](10, 2) NULL,
	[ApprovalStatus] [nvarchar](13) COLLATE Latin1_General_CI_AS NULL,
	[Comment] [nvarchar](2000) COLLATE Latin1_General_CI_AS NULL,
	[BillableAmount_Amount] [decimal](16, 2) NOT NULL,
	[BillableAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[NonBillableAmount_Amount] [decimal](16, 2) NOT NULL,
	[NonBillableAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[AVNoticeId] [bigint] NULL,
	[StateId] [bigint] NOT NULL,
	[PPTVendorId] [bigint] NOT NULL,
	[PayableCodeId] [bigint] NOT NULL,
	[PayableId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[LineofBusinessId] [bigint] NOT NULL,
	[LegalEntityId] [bigint] NOT NULL,
	[CostCenterId] [bigint] NOT NULL,
	[Location] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[WithholdingTaxRate] [decimal](5, 2) NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[PPTInvoices]  WITH CHECK ADD  CONSTRAINT [EPPTInvoice_AVNotice] FOREIGN KEY([AVNoticeId])
REFERENCES [dbo].[AVNotices] ([Id])
GO
ALTER TABLE [dbo].[PPTInvoices] CHECK CONSTRAINT [EPPTInvoice_AVNotice]
GO
ALTER TABLE [dbo].[PPTInvoices]  WITH CHECK ADD  CONSTRAINT [EPPTInvoice_CostCenter] FOREIGN KEY([CostCenterId])
REFERENCES [dbo].[CostCenterConfigs] ([Id])
GO
ALTER TABLE [dbo].[PPTInvoices] CHECK CONSTRAINT [EPPTInvoice_CostCenter]
GO
ALTER TABLE [dbo].[PPTInvoices]  WITH CHECK ADD  CONSTRAINT [EPPTInvoice_LegalEntity] FOREIGN KEY([LegalEntityId])
REFERENCES [dbo].[LegalEntities] ([Id])
GO
ALTER TABLE [dbo].[PPTInvoices] CHECK CONSTRAINT [EPPTInvoice_LegalEntity]
GO
ALTER TABLE [dbo].[PPTInvoices]  WITH CHECK ADD  CONSTRAINT [EPPTInvoice_LineofBusiness] FOREIGN KEY([LineofBusinessId])
REFERENCES [dbo].[LineofBusinesses] ([Id])
GO
ALTER TABLE [dbo].[PPTInvoices] CHECK CONSTRAINT [EPPTInvoice_LineofBusiness]
GO
ALTER TABLE [dbo].[PPTInvoices]  WITH CHECK ADD  CONSTRAINT [EPPTInvoice_Payable] FOREIGN KEY([PayableId])
REFERENCES [dbo].[Payables] ([Id])
GO
ALTER TABLE [dbo].[PPTInvoices] CHECK CONSTRAINT [EPPTInvoice_Payable]
GO
ALTER TABLE [dbo].[PPTInvoices]  WITH CHECK ADD  CONSTRAINT [EPPTInvoice_PayableCode] FOREIGN KEY([PayableCodeId])
REFERENCES [dbo].[PayableCodes] ([Id])
GO
ALTER TABLE [dbo].[PPTInvoices] CHECK CONSTRAINT [EPPTInvoice_PayableCode]
GO
ALTER TABLE [dbo].[PPTInvoices]  WITH CHECK ADD  CONSTRAINT [EPPTInvoice_PPTVendor] FOREIGN KEY([PPTVendorId])
REFERENCES [dbo].[Vendors] ([Id])
GO
ALTER TABLE [dbo].[PPTInvoices] CHECK CONSTRAINT [EPPTInvoice_PPTVendor]
GO
ALTER TABLE [dbo].[PPTInvoices]  WITH CHECK ADD  CONSTRAINT [EPPTInvoice_State] FOREIGN KEY([StateId])
REFERENCES [dbo].[States] ([Id])
GO
ALTER TABLE [dbo].[PPTInvoices] CHECK CONSTRAINT [EPPTInvoice_State]
GO
