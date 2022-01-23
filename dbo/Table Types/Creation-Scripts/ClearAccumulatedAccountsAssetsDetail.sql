CREATE TYPE [dbo].[ClearAccumulatedAccountsAssetsDetail] AS TABLE(
	[PayoffAssetId] [bigint] NOT NULL,
	[CanClearAccumulatedAccount] [bit] NULL
)
GO
