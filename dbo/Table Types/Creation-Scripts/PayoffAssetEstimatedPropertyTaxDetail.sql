CREATE TYPE [dbo].[PayoffAssetEstimatedPropertyTaxDetail] AS TABLE(
	[Year] [decimal](4, 0) NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[EstimatedPropertyTax_Amount] [decimal](16, 2) NOT NULL,
	[EstimatedPropertyTax_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[PayoffAssetId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
