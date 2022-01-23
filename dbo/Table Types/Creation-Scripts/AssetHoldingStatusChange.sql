CREATE TYPE [dbo].[AssetHoldingStatusChange] AS TABLE(
	[Alias] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[NewHoldingStatus] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[PostDate] [date] NOT NULL,
	[GLTransferEffectiveDate] [date] NOT NULL,
	[Status] [nvarchar](9) COLLATE Latin1_General_CI_AS NULL,
	[BookDepreciationGLTemplateId] [bigint] NULL,
	[AssetBookValueAdjustmentGLTemplateId] [bigint] NULL,
	[BookDepreciationTemplateId] [bigint] NULL,
	[BusinessUnitId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
