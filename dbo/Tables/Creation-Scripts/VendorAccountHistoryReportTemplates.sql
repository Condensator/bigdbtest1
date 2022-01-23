SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[VendorAccountHistoryReportTemplates](
	[Id] [bigint] NOT NULL,
	[VendorId] [bigint] NULL,
	[UserId] [bigint] NULL,
	[Name] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[SequenceNumber] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[CommencementDate] [date] NULL,
	[CommencementDateOptions] [nvarchar](17) COLLATE Latin1_General_CI_AS NULL,
	[FromCommencementDate] [date] NULL,
	[ToCommencementDate] [date] NULL,
	[CommencementUpThrough] [date] NULL,
	[CommencementRunDate] [int] NULL,
	[MaturityDateOptions] [nvarchar](17) COLLATE Latin1_General_CI_AS NULL,
	[MaturityTillXDaysFromRunDate] [int] NULL,
	[MaturityDate] [date] NULL,
	[FromMaturityDate] [date] NULL,
	[ToMaturityDate] [date] NULL,
	[MaturityTillDate] [date] NULL,
	[OrderBy] [nvarchar](21) COLLATE Latin1_General_CI_AS NOT NULL,
	[PaymentFrequency] [nvarchar](13) COLLATE Latin1_General_CI_AS NULL,
	[Term] [decimal](10, 6) NULL,
	[ContractCurrency] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[PaymentDate] [date] NULL,
	[DueDate] [date] NULL,
	[InvoiceNumber] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[AmountDue_Amount] [decimal](16, 2) NULL,
	[AmountDue_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[TaxAmount_Amount] [decimal](16, 2) NULL,
	[TaxAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[TaxAssessed_Amount] [decimal](16, 2) NULL,
	[TaxAssessed_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[AmountPaid_Amount] [decimal](16, 2) NULL,
	[AmountPaid_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[TaxPaid_Amount] [decimal](16, 2) NULL,
	[TaxPaid_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[Balance_Amount] [decimal](16, 2) NULL,
	[Balance_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[TaxBalance_Amount] [decimal](16, 2) NULL,
	[TaxBalance_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[CustomerId] [bigint] NULL,
	[FromSequenceNumberId] [bigint] NULL,
	[ToSequenceNumberId] [bigint] NULL,
	[ProgramVendorId] [bigint] NULL,
	[DealerOrDistributerId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[ContractFilterOption] [nvarchar](5) COLLATE Latin1_General_CI_AS NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[VendorAccountHistoryReportTemplates]  WITH CHECK ADD  CONSTRAINT [EReportTemplate_VendorAccountHistoryReportTemplate] FOREIGN KEY([Id])
REFERENCES [dbo].[ReportTemplates] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[VendorAccountHistoryReportTemplates] CHECK CONSTRAINT [EReportTemplate_VendorAccountHistoryReportTemplate]
GO
ALTER TABLE [dbo].[VendorAccountHistoryReportTemplates]  WITH CHECK ADD  CONSTRAINT [EVendorAccountHistoryReportTemplate_Customer] FOREIGN KEY([CustomerId])
REFERENCES [dbo].[Customers] ([Id])
GO
ALTER TABLE [dbo].[VendorAccountHistoryReportTemplates] CHECK CONSTRAINT [EVendorAccountHistoryReportTemplate_Customer]
GO
ALTER TABLE [dbo].[VendorAccountHistoryReportTemplates]  WITH CHECK ADD  CONSTRAINT [EVendorAccountHistoryReportTemplate_DealerOrDistributer] FOREIGN KEY([DealerOrDistributerId])
REFERENCES [dbo].[Vendors] ([Id])
GO
ALTER TABLE [dbo].[VendorAccountHistoryReportTemplates] CHECK CONSTRAINT [EVendorAccountHistoryReportTemplate_DealerOrDistributer]
GO
ALTER TABLE [dbo].[VendorAccountHistoryReportTemplates]  WITH CHECK ADD  CONSTRAINT [EVendorAccountHistoryReportTemplate_FromSequenceNumber] FOREIGN KEY([FromSequenceNumberId])
REFERENCES [dbo].[Contracts] ([Id])
GO
ALTER TABLE [dbo].[VendorAccountHistoryReportTemplates] CHECK CONSTRAINT [EVendorAccountHistoryReportTemplate_FromSequenceNumber]
GO
ALTER TABLE [dbo].[VendorAccountHistoryReportTemplates]  WITH CHECK ADD  CONSTRAINT [EVendorAccountHistoryReportTemplate_ProgramVendor] FOREIGN KEY([ProgramVendorId])
REFERENCES [dbo].[Vendors] ([Id])
GO
ALTER TABLE [dbo].[VendorAccountHistoryReportTemplates] CHECK CONSTRAINT [EVendorAccountHistoryReportTemplate_ProgramVendor]
GO
ALTER TABLE [dbo].[VendorAccountHistoryReportTemplates]  WITH CHECK ADD  CONSTRAINT [EVendorAccountHistoryReportTemplate_ToSequenceNumber] FOREIGN KEY([ToSequenceNumberId])
REFERENCES [dbo].[Contracts] ([Id])
GO
ALTER TABLE [dbo].[VendorAccountHistoryReportTemplates] CHECK CONSTRAINT [EVendorAccountHistoryReportTemplate_ToSequenceNumber]
GO
ALTER TABLE [dbo].[VendorAccountHistoryReportTemplates]  WITH CHECK ADD  CONSTRAINT [EVendorAccountHistoryReportTemplate_User] FOREIGN KEY([UserId])
REFERENCES [dbo].[Users] ([Id])
GO
ALTER TABLE [dbo].[VendorAccountHistoryReportTemplates] CHECK CONSTRAINT [EVendorAccountHistoryReportTemplate_User]
GO
ALTER TABLE [dbo].[VendorAccountHistoryReportTemplates]  WITH CHECK ADD  CONSTRAINT [EVendorAccountHistoryReportTemplate_Vendor] FOREIGN KEY([VendorId])
REFERENCES [dbo].[Vendors] ([Id])
GO
ALTER TABLE [dbo].[VendorAccountHistoryReportTemplates] CHECK CONSTRAINT [EVendorAccountHistoryReportTemplate_Vendor]
GO
