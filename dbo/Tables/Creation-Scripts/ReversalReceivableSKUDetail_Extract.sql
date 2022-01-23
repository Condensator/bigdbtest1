SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ReversalReceivableSKUDetail_Extract](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[ReceivableSKUId] [bigint] NOT NULL,
	[ReceivableTaxDetailId] [bigint] NULL,
	[Currency] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[Cost] [decimal](16, 2) NOT NULL,
	[ExtendedPrice] [decimal](16, 2) NOT NULL,
	[FairMarketValue] [decimal](16, 2) NOT NULL,
	[AssetSKUId] [bigint] NULL,
	[IsExemptAtAssetSKU] [bit] NOT NULL,
	[AmountBilledToDate] [decimal](16, 2) NOT NULL,
	[JobStepInstanceId] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
