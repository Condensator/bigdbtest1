SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TaxSourceDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[SourceId] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[SourceTable] [nvarchar](20) COLLATE Latin1_General_CI_AS NOT NULL,
	[EffectiveDate] [date] NULL,
	[TaxLevel] [nvarchar](7) COLLATE Latin1_General_CI_AS NOT NULL,
	[BuyerLocationId] [bigint] NOT NULL,
	[SellerLocationId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[DealCountryId] [bigint] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
