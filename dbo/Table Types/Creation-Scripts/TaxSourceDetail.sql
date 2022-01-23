CREATE TYPE [dbo].[TaxSourceDetail] AS TABLE(
	[SourceId] [bigint] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[SourceTable] [nvarchar](20) COLLATE Latin1_General_CI_AS NOT NULL,
	[EffectiveDate] [date] NULL,
	[DealCountryId] [bigint] NOT NULL,
	[TaxLevel] [nvarchar](7) COLLATE Latin1_General_CI_AS NOT NULL,
	[BuyerLocationId] [bigint] NOT NULL,
	[SellerLocationId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
