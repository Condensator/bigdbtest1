SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LeaseAssetIncomeDetails](
	[Id] [bigint] NOT NULL,
	[Income_Amount] [decimal](16, 2) NOT NULL,
	[Income_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ResidualIncome_Amount] [decimal](16, 2) NOT NULL,
	[ResidualIncome_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[LeaseIncome_Amount] [decimal](16, 2) NOT NULL,
	[LeaseIncome_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[LeaseResidualIncome_Amount] [decimal](16, 2) NOT NULL,
	[LeaseResidualIncome_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[FinanceIncome_Amount] [decimal](16, 2) NOT NULL,
	[FinanceIncome_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[FinanceResidualIncome_Amount] [decimal](16, 2) NOT NULL,
	[FinanceResidualIncome_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[SalesTypeNBV_Amount] [decimal](16, 2) NOT NULL,
	[SalesTypeNBV_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[AssetYieldForLeaseComponents] [decimal](28, 18) NOT NULL,
	[AssetYieldForFinanceComponents] [decimal](28, 18) NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[LeaseAssetIncomeDetails]  WITH CHECK ADD  CONSTRAINT [ELeaseAsset_LeaseAssetIncomeDetail] FOREIGN KEY([Id])
REFERENCES [dbo].[LeaseAssets] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[LeaseAssetIncomeDetails] CHECK CONSTRAINT [ELeaseAsset_LeaseAssetIncomeDetail]
GO
