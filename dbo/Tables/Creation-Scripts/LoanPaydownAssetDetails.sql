SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LoanPaydownAssetDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[AssetPaydownStatus] [nvarchar](17) COLLATE Latin1_General_CI_AS NULL,
	[PrePaymentAmount_Amount] [decimal](16, 2) NOT NULL,
	[PrePaymentAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[AssetValuation_Amount] [decimal](16, 2) NOT NULL,
	[AssetValuation_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[NetWritedown_Amount] [decimal](16, 2) NOT NULL,
	[NetWritedown_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[WrittenDownNBV_Amount] [decimal](16, 2) NOT NULL,
	[WrittenDownNBV_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[AssetCost_Amount] [decimal](16, 2) NOT NULL,
	[AssetCost_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[AssetId] [bigint] NOT NULL,
	[LoanPaydownId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[IsPartiallyOwned] [bit] NOT NULL,
	[HoldingStatus] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[LoanPaydownAssetDetails]  WITH CHECK ADD  CONSTRAINT [ELoanPaydown_LoanPaydownAssetDetails] FOREIGN KEY([LoanPaydownId])
REFERENCES [dbo].[LoanPaydowns] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[LoanPaydownAssetDetails] CHECK CONSTRAINT [ELoanPaydown_LoanPaydownAssetDetails]
GO
ALTER TABLE [dbo].[LoanPaydownAssetDetails]  WITH CHECK ADD  CONSTRAINT [ELoanPaydownAssetDetail_Asset] FOREIGN KEY([AssetId])
REFERENCES [dbo].[Assets] ([Id])
GO
ALTER TABLE [dbo].[LoanPaydownAssetDetails] CHECK CONSTRAINT [ELoanPaydownAssetDetail_Asset]
GO
