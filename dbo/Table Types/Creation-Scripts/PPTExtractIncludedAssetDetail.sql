CREATE TYPE [dbo].[PPTExtractIncludedAssetDetail] AS TABLE(
	[NumberOfAssets] [bigint] NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[TotalPPTBasis_Amount] [decimal](16, 2) NOT NULL,
	[TotalPPTBasis_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[NumberOfAssetsToTransfer] [bigint] NULL,
	[TotalPPTBasisToTransfer_Amount] [decimal](16, 2) NOT NULL,
	[TotalPPTBasisToTransfer_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[ExportFile] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[StateId] [bigint] NULL,
	[LegalEntityId] [bigint] NULL,
	[PPTExtractDetailId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
