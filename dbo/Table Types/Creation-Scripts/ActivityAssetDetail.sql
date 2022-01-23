CREATE TYPE [dbo].[ActivityAssetDetail] AS TABLE(
	[IsActive] [bit] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[NetValue_Amount] [decimal](16, 2) NULL,
	[NetValue_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[AssetId] [bigint] NOT NULL,
	[ActivityForCustomerId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
