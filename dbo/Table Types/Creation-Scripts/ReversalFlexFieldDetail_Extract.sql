CREATE TYPE [dbo].[ReversalFlexFieldDetail_Extract] AS TABLE(
	[AssetId] [bigint] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[GrossVehicleWeight] [int] NULL,
	[SaleLeasebackCode] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[IsElectronicallyDelivered] [bit] NOT NULL,
	[SalesTaxExemptionLevel] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[AssetCatalogNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[AssetTypeId] [bigint] NOT NULL,
	[JobStepInstanceId] [bigint] NOT NULL,
	[Usage] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[AssetUsageCondition] [nvarchar](4) COLLATE Latin1_General_CI_AS NULL,
	[AssetSerialOrVIN] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[AssetSKUId] [bigint] NULL,
	[IsSKU] [bit] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
