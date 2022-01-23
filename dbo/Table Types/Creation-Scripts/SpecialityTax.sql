CREATE TYPE [dbo].[SpecialityTax] AS TABLE(
	[FloridaStampTaxRate] [decimal](10, 6) NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[FLStampTaxContractCeilingAmount_Amount] [decimal](16, 2) NOT NULL,
	[FLStampTaxContractCeilingAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[TennesseeIndebtednessTaxRate] [decimal](10, 6) NOT NULL,
	[TNIndebtednessTaxCeilingAmount_Amount] [decimal](16, 2) NOT NULL,
	[TNIndebtednessTaxCeilingAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[TNIndebtednessDiligenzFee] [decimal](10, 6) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
