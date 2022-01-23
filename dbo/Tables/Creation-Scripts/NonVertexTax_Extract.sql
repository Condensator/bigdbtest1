SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[NonVertexTax_Extract](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[ReceivableId] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ReceivableDetailId] [bigint] NOT NULL,
	[AssetId] [bigint] NULL,
	[Currency] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[CalculatedTax] [decimal](16, 2) NOT NULL,
	[TaxResult] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[JurisdictionId] [bigint] NOT NULL,
	[JurisdictionLevel] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[ImpositionType] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[EffectiveRate] [decimal](10, 6) NOT NULL,
	[ExemptionType] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[ExemptionAmount] [decimal](16, 2) NOT NULL,
	[JobStepInstanceId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[TaxTypeId] [bigint] NULL,
	[IsCashBased] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
