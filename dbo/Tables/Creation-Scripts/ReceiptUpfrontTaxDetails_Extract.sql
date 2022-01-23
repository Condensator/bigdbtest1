SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ReceiptUpfrontTaxDetails_Extract](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[ReceiptId] [bigint] NOT NULL,
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
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
