SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SpecialityTaxes](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[FloridaStampTaxRate] [decimal](10, 6) NOT NULL,
	[FLStampTaxContractCeilingAmount_Amount] [decimal](16, 2) NOT NULL,
	[FLStampTaxContractCeilingAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[TennesseeIndebtednessTaxRate] [decimal](10, 6) NOT NULL,
	[TNIndebtednessTaxCeilingAmount_Amount] [decimal](16, 2) NOT NULL,
	[TNIndebtednessTaxCeilingAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[TNIndebtednessDiligenzFee] [decimal](10, 6) NOT NULL,
	[IsActive] [bit] NOT NULL,
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
