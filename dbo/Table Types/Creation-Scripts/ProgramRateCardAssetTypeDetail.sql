CREATE TYPE [dbo].[ProgramRateCardAssetTypeDetail] AS TABLE(
	[AssetType] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ProgramRateCardId] [bigint] NULL,
	[PromotionCode] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[ProgramDetailId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
