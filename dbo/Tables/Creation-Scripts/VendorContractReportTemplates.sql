SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[VendorContractReportTemplates](
	[Id] [bigint] NOT NULL,
	[Status] [nvarchar](16) COLLATE Latin1_General_CI_AS NULL,
	[CommencementDate] [nvarchar](17) COLLATE Latin1_General_CI_AS NULL,
	[FromCommencement] [date] NULL,
	[ToCommencement] [date] NULL,
	[CommencementUpThrough] [date] NULL,
	[CommencementRunDate] [int] NULL,
	[SortBy] [nvarchar](25) COLLATE Latin1_General_CI_AS NULL,
	[FromDate] [date] NULL,
	[ToDate] [date] NULL,
	[MaturityDate] [nvarchar](17) COLLATE Latin1_General_CI_AS NULL,
	[UpThroughDate] [date] NULL,
	[DaysFromRunDate] [int] NULL,
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
ALTER TABLE [dbo].[VendorContractReportTemplates]  WITH CHECK ADD  CONSTRAINT [EReportTemplate_VendorContractReportTemplate] FOREIGN KEY([Id])
REFERENCES [dbo].[ReportTemplates] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[VendorContractReportTemplates] CHECK CONSTRAINT [EReportTemplate_VendorContractReportTemplate]
GO
ALTER TABLE [dbo].[VendorContractReportTemplates]  WITH CHECK ADD  CONSTRAINT [EVendorContractReportTemplate_Customer] FOREIGN KEY([CustomerId])
REFERENCES [dbo].[Customers] ([Id])
GO
ALTER TABLE [dbo].[VendorContractReportTemplates] CHECK CONSTRAINT [EVendorContractReportTemplate_Customer]
GO
ALTER TABLE [dbo].[VendorContractReportTemplates]  WITH CHECK ADD  CONSTRAINT [EVendorContractReportTemplate_DealerOrDistributer] FOREIGN KEY([DealerOrDistributerId])
REFERENCES [dbo].[Vendors] ([Id])
GO
ALTER TABLE [dbo].[VendorContractReportTemplates] CHECK CONSTRAINT [EVendorContractReportTemplate_DealerOrDistributer]
GO
ALTER TABLE [dbo].[VendorContractReportTemplates]  WITH CHECK ADD  CONSTRAINT [EVendorContractReportTemplate_FromSequenceNumber] FOREIGN KEY([FromSequenceNumberId])
REFERENCES [dbo].[Contracts] ([Id])
GO
ALTER TABLE [dbo].[VendorContractReportTemplates] CHECK CONSTRAINT [EVendorContractReportTemplate_FromSequenceNumber]
GO
ALTER TABLE [dbo].[VendorContractReportTemplates]  WITH CHECK ADD  CONSTRAINT [EVendorContractReportTemplate_ProgramVendor] FOREIGN KEY([ProgramVendorId])
REFERENCES [dbo].[Vendors] ([Id])
GO
ALTER TABLE [dbo].[VendorContractReportTemplates] CHECK CONSTRAINT [EVendorContractReportTemplate_ProgramVendor]
GO
ALTER TABLE [dbo].[VendorContractReportTemplates]  WITH CHECK ADD  CONSTRAINT [EVendorContractReportTemplate_ToSequenceNumber] FOREIGN KEY([ToSequenceNumberId])
REFERENCES [dbo].[Contracts] ([Id])
GO
ALTER TABLE [dbo].[VendorContractReportTemplates] CHECK CONSTRAINT [EVendorContractReportTemplate_ToSequenceNumber]
GO
