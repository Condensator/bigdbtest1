SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SalesTaxAssetLocationDetail_Extract](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[ReceivableDetailId] [bigint] NOT NULL,
	[AssetId] [bigint] NOT NULL,
	[LocationId] [bigint] NOT NULL,
	[PreviousLocationId] [bigint] NULL,
	[LocationTaxBasisType] [nvarchar](5) COLLATE Latin1_General_CI_AS NULL,
	[ReciprocityAmount] [decimal](16, 2) NOT NULL,
	[LienCredit] [decimal](16, 2) NOT NULL,
	[LocationEffectiveDate] [date] NULL,
	[ReceivableDueDate] [date] NOT NULL,
	[AssetlocationId] [bigint] NULL,
	[CustomerLocationId] [bigint] NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[JobStepInstanceId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[UpfrontTaxAssessedInLegacySystem] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
