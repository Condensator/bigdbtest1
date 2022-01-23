CREATE TYPE [dbo].[AssetSplit] AS TABLE(
	[SplitType] [nvarchar](17) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[Alias] [nvarchar](50) COLLATE Latin1_General_CI_AS NOT NULL,
	[ApprovalStatus] [nvarchar](18) COLLATE Latin1_General_CI_AS NOT NULL,
	[FeatureAssetId] [bigint] NULL,
	[JobStepInstanceId] [bigint] NULL,
	[BusinessUnitId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
