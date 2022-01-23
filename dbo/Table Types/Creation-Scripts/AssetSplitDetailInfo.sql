CREATE TYPE [dbo].[AssetSplitDetailInfo] AS TABLE(
	[NewAssetCost_Amount] [decimal](16, 2) NOT NULL,
	[NewAssetCost_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[Weightage] [decimal](28, 18) NULL,
	[NewQuantity] [int] NOT NULL,
	[Alias] [nvarchar](50) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[AssetSplitDetailId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
