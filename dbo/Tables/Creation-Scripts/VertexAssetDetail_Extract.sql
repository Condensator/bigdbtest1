SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[VertexAssetDetail_Extract](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[AssetId] [bigint] NOT NULL,
	[TitleTransferCode] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[AssetType] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[SaleLeasebackCode] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[IsElectronicallyDelivered] [bit] NOT NULL,
	[GrossVehicleWeight] [decimal](16, 2) NOT NULL,
	[SalesTaxExemptionLevel] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[AssetCatalogNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[ContractTypeName] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[JobStepInstanceId] [bigint] NOT NULL,
	[Usage] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[RowVersion] [timestamp] NOT NULL,
	[ContractId] [bigint] NULL,
	[SalesTaxRemittanceResponsibility] [nvarchar](8) COLLATE Latin1_General_CI_AS NULL,
	[PreviousSalesTaxRemittanceResponsibility] [nvarchar](8) COLLATE Latin1_General_CI_AS NULL,
	[PreviousSalesTaxRemittanceResponsibilityEffectiveTillDate] [date] NULL,
	[AssetSerialOrVIN] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[AssetUsageCondition] [nvarchar](4) COLLATE Latin1_General_CI_AS NULL,
	[IsSKU] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
