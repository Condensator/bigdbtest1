SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AssetFloatRateIncomes](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[CustomerIncomeAmount_Amount] [decimal](16, 2) NOT NULL,
	[CustomerIncomeAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[CustomerIncomeAccruedAmount_Amount] [decimal](16, 2) NOT NULL,
	[CustomerIncomeAccruedAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[CustomerReceivableAmount_Amount] [decimal](16, 2) NOT NULL,
	[CustomerReceivableAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[AssetId] [bigint] NOT NULL,
	[LeaseFloatRateIncomeId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[AssetFloatRateIncomes]  WITH CHECK ADD  CONSTRAINT [EAssetFloatRateIncome_Asset] FOREIGN KEY([AssetId])
REFERENCES [dbo].[Assets] ([Id])
GO
ALTER TABLE [dbo].[AssetFloatRateIncomes] CHECK CONSTRAINT [EAssetFloatRateIncome_Asset]
GO
ALTER TABLE [dbo].[AssetFloatRateIncomes]  WITH CHECK ADD  CONSTRAINT [ELeaseFloatRateIncome_AssetFloatRateIncomes] FOREIGN KEY([LeaseFloatRateIncomeId])
REFERENCES [dbo].[LeaseFloatRateIncomes] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[AssetFloatRateIncomes] CHECK CONSTRAINT [ELeaseFloatRateIncome_AssetFloatRateIncomes]
GO
