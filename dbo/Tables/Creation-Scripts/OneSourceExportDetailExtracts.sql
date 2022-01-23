SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[OneSourceExportDetailExtracts](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[AssetNumber] [bigint] NULL,
	[LeaseNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[ItemType] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[AssetDescription] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[AcquisitionDate] [date] NULL,
	[AssetCost] [decimal](16, 2) NULL,
	[AssetAddressLine1] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[AssetAddressLine2] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[AssetAddressLine3] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[AssetCity] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[AssetCountyName] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[AssetState] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[AssetZipCode] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[EquipmentCode] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[SalesTaxRate] [decimal](16, 2) NULL,
	[LeaseType] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[AssetSerialNumber] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[FederalTaxDep] [decimal](16, 2) NULL,
	[Manufacturer] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[ModelYear] [decimal](4, 0) NULL,
	[AgreementCustomerName] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[CustomerAddressLine1] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[CustomerAddressLine2] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[CustomerAddressLine3] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[CustomerCity] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[CustomerState] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[CustomerZipCode] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[TaxExempt] [bit] NULL,
	[LegalEntityId] [bigint] NULL,
	[JobStepInstanceId] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RowVersion] [timestamp] NOT NULL,
	[IsIncluded] [bit] NOT NULL,
	[RejectReason] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[FileName] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[PreviousLeaseNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[IsDisposedAssetReported] [bit] NOT NULL,
	[AsOfDate] [date] NULL,
	[Quantity] [int] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
