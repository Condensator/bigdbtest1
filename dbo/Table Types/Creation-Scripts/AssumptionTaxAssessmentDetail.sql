CREATE TYPE [dbo].[AssumptionTaxAssessmentDetail] AS TABLE(
	[SalesTaxRate] [decimal](9, 5) NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[SalesTaxAmount_Amount] [decimal](16, 2) NOT NULL,
	[SalesTaxAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[OtherBasisTypesAvailable] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[UpfrontTaxMode] [nvarchar](6) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[IsDummy] [bit] NOT NULL,
	[TaxBasisTypeId] [bigint] NULL,
	[LocationId] [bigint] NULL,
	[AssetTypeId] [bigint] NULL,
	[TaxCodeId] [bigint] NULL,
	[TaxTypeId] [bigint] NULL,
	[AssumptionId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
