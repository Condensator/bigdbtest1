CREATE TYPE [dbo].[SalesTaxAssetLocationDetail_Extract] AS TABLE(
	[AssetId] [bigint] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ReceivableDetailId] [bigint] NOT NULL,
	[LocationId] [bigint] NOT NULL,
	[PreviousLocationId] [bigint] NULL,
	[LocationTaxBasisType] [nvarchar](5) COLLATE Latin1_General_CI_AS NULL,
	[ReciprocityAmount] [decimal](16, 2) NOT NULL,
	[LienCredit] [decimal](16, 2) NOT NULL,
	[LocationEffectiveDate] [date] NULL,
	[ReceivableDueDate] [date] NOT NULL,
	[AssetlocationId] [bigint] NULL,
	[CustomerLocationId] [bigint] NULL,
	[JobStepInstanceId] [bigint] NOT NULL,
	[UpfrontTaxAssessedInLegacySystem] [bit] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
