CREATE TYPE [dbo].[LeaseAmendmentImpairmentAssetDetail] AS TABLE(
	[ResidualImpairmentAmount_Amount] [decimal](16, 2) NULL,
	[ResidualImpairmentAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[NBVImpairmentAmount_Amount] [decimal](16, 2) NULL,
	[NBVImpairmentAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[PreRestructureBookedResidualAmount_Amount] [decimal](16, 2) NULL,
	[PreRestructureBookedResidualAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[PostRestructureBookedResidualAmount_Amount] [decimal](16, 2) NULL,
	[PostRestructureBookedResidualAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[PVOfAsset_Amount] [decimal](16, 2) NULL,
	[PVOfAsset_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[AssetId] [bigint] NOT NULL,
	[BookDepreciationTemplateId] [bigint] NULL,
	[LeaseAmendmentId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
