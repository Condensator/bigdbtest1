CREATE TYPE [dbo].[PropertyTaxCombinedTaxRate] AS TABLE(
	[TaxAreaId] [bigint] NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[TaxRate] [decimal](10, 6) NULL,
	[IsActive] [bit] NOT NULL,
	[ExemptionCode] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[AssetId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
