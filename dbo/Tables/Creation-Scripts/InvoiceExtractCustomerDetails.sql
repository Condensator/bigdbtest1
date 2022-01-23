SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[InvoiceExtractCustomerDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[InvoiceId] [bigint] NOT NULL,
	[InvoiceType] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[InvoiceNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[InvoiceRunDate] [date] NULL,
	[DueDate] [date] NULL,
	[BillToId] [bigint] NOT NULL,
	[CustomerName] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[CustomerNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[AttentionLine] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[TotalReceivableAmount_Amount] [decimal](16, 2) NULL,
	[TotalReceivableAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[TotalTaxAmount_Amount] [decimal](16, 2) NULL,
	[TotalTaxAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[RemitToName] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[LegalEntityNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[LegalEntityName] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[IsACH] [bit] NOT NULL,
	[RemitToCode] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[InvoiceNumberLabel] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[InvoiceRunDateLabel] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[BillingAddressLine1] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[BillingAddressLine2] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[BillingCity] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[BillingState] [nvarchar](5) COLLATE Latin1_General_CI_AS NULL,
	[BillingZip] [nvarchar](12) COLLATE Latin1_General_CI_AS NULL,
	[BillingCountry] [nvarchar](5) COLLATE Latin1_General_CI_AS NULL,
	[ReportFormatName] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[GSTId] [nvarchar](15) COLLATE Latin1_General_CI_AS NULL,
	[LessorAddressLine1] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[LessorAddressLine2] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[LessorCity] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[LessorState] [nvarchar](5) COLLATE Latin1_General_CI_AS NULL,
	[LessorZip] [nvarchar](12) COLLATE Latin1_General_CI_AS NULL,
	[LessorCountry] [nvarchar](5) COLLATE Latin1_General_CI_AS NULL,
	[LessorContactPhone] [nvarchar](15) COLLATE Latin1_General_CI_AS NULL,
	[LessorContactEmail] [nvarchar](70) COLLATE Latin1_General_CI_AS NULL,
	[LessorWebAddress] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[CustomerComments] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[CustomerInvoiceCommentBeginDate] [date] NULL,
	[CustomerInvoiceCommentEndDate] [date] NULL,
	[GenerateInvoiceAddendum] [bit] NOT NULL,
	[AttributeName] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[UseDynamicContentForInvoiceAddendumBody] [bit] NOT NULL,
	[GroupAssets] [bit] NOT NULL,
	[DeliverInvoiceViaEmail] [bit] NOT NULL,
	[OCRMCR] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[JobStepInstanceId] [bigint] NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RowVersion] [timestamp] NOT NULL,
	[LogoId] [bigint] NULL,
	[ExternalExtractBatchId] [bigint] NULL,
	[LessorTaxRegistrationNumber] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[CustomerTaxRegistrationNumber] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[CustomerMainAddressLine1] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[CustomerMainAddressLine2] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[CustomerMainCity] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[CustomerMainState] [nvarchar](5) COLLATE Latin1_General_CI_AS NULL,
	[CustomerMainZip] [nvarchar](12) COLLATE Latin1_General_CI_AS NULL,
	[CustomerMainCountry] [nvarchar](5) COLLATE Latin1_General_CI_AS NULL,
	[OriginalInvoiceNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[CreditReason] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[RemitToAccountNumber] [nvarchar](20) COLLATE Latin1_General_CI_AS NULL,
	[RemitToIBAN] [nvarchar](34) COLLATE Latin1_General_CI_AS NULL,
	[RemitToSWIFTCode] [nvarchar](20) COLLATE Latin1_General_CI_AS NULL,
	[RemitToTransitCode] [nvarchar](20) COLLATE Latin1_General_CI_AS NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[InvoiceExtractCustomerDetails]  WITH CHECK ADD  CONSTRAINT [EInvoiceExtractCustomerDetail_BillTo] FOREIGN KEY([BillToId])
REFERENCES [dbo].[BillToes] ([Id])
GO
ALTER TABLE [dbo].[InvoiceExtractCustomerDetails] CHECK CONSTRAINT [EInvoiceExtractCustomerDetail_BillTo]
GO
ALTER TABLE [dbo].[InvoiceExtractCustomerDetails]  WITH CHECK ADD  CONSTRAINT [EInvoiceExtractCustomerDetail_Invoice] FOREIGN KEY([InvoiceId])
REFERENCES [dbo].[ReceivableInvoices] ([Id])
GO
ALTER TABLE [dbo].[InvoiceExtractCustomerDetails] CHECK CONSTRAINT [EInvoiceExtractCustomerDetail_Invoice]
GO
ALTER TABLE [dbo].[InvoiceExtractCustomerDetails]  WITH CHECK ADD  CONSTRAINT [EInvoiceExtractCustomerDetail_JobStepInstance] FOREIGN KEY([JobStepInstanceId])
REFERENCES [dbo].[JobStepInstances] ([Id])
GO
ALTER TABLE [dbo].[InvoiceExtractCustomerDetails] CHECK CONSTRAINT [EInvoiceExtractCustomerDetail_JobStepInstance]
GO
ALTER TABLE [dbo].[InvoiceExtractCustomerDetails]  WITH CHECK ADD  CONSTRAINT [EInvoiceExtractCustomerDetail_Logo] FOREIGN KEY([LogoId])
REFERENCES [dbo].[Logoes] ([Id])
GO
ALTER TABLE [dbo].[InvoiceExtractCustomerDetails] CHECK CONSTRAINT [EInvoiceExtractCustomerDetail_Logo]
GO
