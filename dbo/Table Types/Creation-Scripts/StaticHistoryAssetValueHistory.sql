CREATE TYPE [dbo].[StaticHistoryAssetValueHistory] AS TABLE(
	[AsOfDate] [date] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[Transaction] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[OriginalCost_Amount] [decimal](16, 2) NOT NULL,
	[OriginalCost_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[NetValue_Amount] [decimal](16, 2) NOT NULL,
	[NetValue_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[ChangeInAmount_Amount] [decimal](16, 2) NOT NULL,
	[ChangeInAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[StaticHistoryAssetId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
