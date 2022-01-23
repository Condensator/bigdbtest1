CREATE TYPE [dbo].[ExpectedEntryItemDetail] AS TABLE(
	[GLTransactionType] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[EntryItemName] [nvarchar](60) COLLATE Latin1_General_CI_AS NULL,
	[IsDebit] [nvarchar](10) COLLATE Latin1_General_CI_AS NULL,
	[IsCashBased] [nvarchar](10) COLLATE Latin1_General_CI_AS NULL,
	[IsAccrualBased] [nvarchar](10) COLLATE Latin1_General_CI_AS NULL,
	[IsMemoBased] [nvarchar](10) COLLATE Latin1_General_CI_AS NULL,
	[IsPrepaidApplicable] [nvarchar](10) COLLATE Latin1_General_CI_AS NULL,
	[AssetComponent] [nvarchar](20) COLLATE Latin1_General_CI_AS NULL,
	[IsInterCompany] [nvarchar](10) COLLATE Latin1_General_CI_AS NULL,
	[IsFunderOwnedTax] [nvarchar](10) COLLATE Latin1_General_CI_AS NULL,
	[IsOTP] [nvarchar](10) COLLATE Latin1_General_CI_AS NULL,
	[IsSupplemental] [nvarchar](10) COLLATE Latin1_General_CI_AS NULL,
	[IsBlendedItem] [nvarchar](10) COLLATE Latin1_General_CI_AS NULL,
	[IsVendorOwned] [nvarchar](10) COLLATE Latin1_General_CI_AS NULL
)
GO
