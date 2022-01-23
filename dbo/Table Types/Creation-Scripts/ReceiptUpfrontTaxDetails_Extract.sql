CREATE TYPE [dbo].[ReceiptUpfrontTaxDetails_Extract] AS TABLE(
	[ReceiptId] [bigint] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ContractId] [bigint] NOT NULL,
	[AssetId] [bigint] NOT NULL,
	[LeaseAssetSalesTaxResposibillity] [nvarchar](8) COLLATE Latin1_General_CI_AS NULL,
	[SalesTaxResposibillityFromHistories] [nvarchar](8) COLLATE Latin1_General_CI_AS NULL,
	[EffectiveTillDate] [date] NULL,
	[VendorId] [bigint] NULL,
	[PayableCodeId] [bigint] NULL,
	[LeaseAssetVendorRemitToId] [bigint] NULL,
	[VendorRemitToIdFromHistories] [bigint] NULL,
	[JobStepInstanceId] [bigint] NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
