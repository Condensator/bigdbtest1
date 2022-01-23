CREATE TYPE [dbo].[TaxMatrix] AS TABLE(
	[EffectiveDate] [date] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[TaxLevel] [nvarchar](7) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[TaxCodeId] [bigint] NOT NULL,
	[TaxReceivableTypeId] [bigint] NULL,
	[PayableTypeId] [bigint] NULL,
	[TaxAssetTypeId] [bigint] NULL,
	[BuyerCountryId] [bigint] NULL,
	[SellerCountryId] [bigint] NULL,
	[BuyerStateId] [bigint] NULL,
	[SellerStateId] [bigint] NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
