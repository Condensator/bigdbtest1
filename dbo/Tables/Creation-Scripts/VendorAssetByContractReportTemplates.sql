SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[VendorAssetByContractReportTemplates](
	[Id] [bigint] NOT NULL,
	[VendorId] [bigint] NULL,
	[UserId] [bigint] NULL,
	[Name] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[SequenceNumber] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[Location] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[State] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[Country] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[ContractStatus] [nvarchar](16) COLLATE Latin1_General_CI_AS NULL,
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
	[SerialNumber] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[OrderBy] [nvarchar](21) COLLATE Latin1_General_CI_AS NOT NULL,
	[AssetId] [bigint] NULL,
	[AssetAlias] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[Description] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[Manufacturer] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[PartNumber] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[ModelYear] [decimal](4, 0) NULL,
	[Status] [nvarchar](17) COLLATE Latin1_General_CI_AS NULL,
	[AssetType] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[Term] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[CustomerName] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[CustomerNumber] [nvarchar](20) COLLATE Latin1_General_CI_AS NULL,
	[UDF1Value] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[UDF2Value] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[UDF3Value] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[UDF4Value] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[UDF5Value] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
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
ALTER TABLE [dbo].[VendorAssetByContractReportTemplates]  WITH CHECK ADD  CONSTRAINT [EReportTemplate_VendorAssetByContractReportTemplate] FOREIGN KEY([Id])
REFERENCES [dbo].[ReportTemplates] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[VendorAssetByContractReportTemplates] CHECK CONSTRAINT [EReportTemplate_VendorAssetByContractReportTemplate]
GO
ALTER TABLE [dbo].[VendorAssetByContractReportTemplates]  WITH CHECK ADD  CONSTRAINT [EVendorAssetByContractReportTemplate_Asset] FOREIGN KEY([AssetId])
REFERENCES [dbo].[Assets] ([Id])
GO
ALTER TABLE [dbo].[VendorAssetByContractReportTemplates] CHECK CONSTRAINT [EVendorAssetByContractReportTemplate_Asset]
GO
ALTER TABLE [dbo].[VendorAssetByContractReportTemplates]  WITH CHECK ADD  CONSTRAINT [EVendorAssetByContractReportTemplate_Customer] FOREIGN KEY([CustomerId])
REFERENCES [dbo].[Customers] ([Id])
GO
ALTER TABLE [dbo].[VendorAssetByContractReportTemplates] CHECK CONSTRAINT [EVendorAssetByContractReportTemplate_Customer]
GO
ALTER TABLE [dbo].[VendorAssetByContractReportTemplates]  WITH CHECK ADD  CONSTRAINT [EVendorAssetByContractReportTemplate_DealerOrDistributer] FOREIGN KEY([DealerOrDistributerId])
REFERENCES [dbo].[Vendors] ([Id])
GO
ALTER TABLE [dbo].[VendorAssetByContractReportTemplates] CHECK CONSTRAINT [EVendorAssetByContractReportTemplate_DealerOrDistributer]
GO
ALTER TABLE [dbo].[VendorAssetByContractReportTemplates]  WITH CHECK ADD  CONSTRAINT [EVendorAssetByContractReportTemplate_FromSequenceNumber] FOREIGN KEY([FromSequenceNumberId])
REFERENCES [dbo].[Contracts] ([Id])
GO
ALTER TABLE [dbo].[VendorAssetByContractReportTemplates] CHECK CONSTRAINT [EVendorAssetByContractReportTemplate_FromSequenceNumber]
GO
ALTER TABLE [dbo].[VendorAssetByContractReportTemplates]  WITH CHECK ADD  CONSTRAINT [EVendorAssetByContractReportTemplate_ProgramVendor] FOREIGN KEY([ProgramVendorId])
REFERENCES [dbo].[Vendors] ([Id])
GO
ALTER TABLE [dbo].[VendorAssetByContractReportTemplates] CHECK CONSTRAINT [EVendorAssetByContractReportTemplate_ProgramVendor]
GO
ALTER TABLE [dbo].[VendorAssetByContractReportTemplates]  WITH CHECK ADD  CONSTRAINT [EVendorAssetByContractReportTemplate_ToSequenceNumber] FOREIGN KEY([ToSequenceNumberId])
REFERENCES [dbo].[Contracts] ([Id])
GO
ALTER TABLE [dbo].[VendorAssetByContractReportTemplates] CHECK CONSTRAINT [EVendorAssetByContractReportTemplate_ToSequenceNumber]
GO
ALTER TABLE [dbo].[VendorAssetByContractReportTemplates]  WITH CHECK ADD  CONSTRAINT [EVendorAssetByContractReportTemplate_User] FOREIGN KEY([UserId])
REFERENCES [dbo].[Users] ([Id])
GO
ALTER TABLE [dbo].[VendorAssetByContractReportTemplates] CHECK CONSTRAINT [EVendorAssetByContractReportTemplate_User]
GO
ALTER TABLE [dbo].[VendorAssetByContractReportTemplates]  WITH CHECK ADD  CONSTRAINT [EVendorAssetByContractReportTemplate_Vendor] FOREIGN KEY([VendorId])
REFERENCES [dbo].[Vendors] ([Id])
GO
ALTER TABLE [dbo].[VendorAssetByContractReportTemplates] CHECK CONSTRAINT [EVendorAssetByContractReportTemplate_Vendor]
GO
