SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CollateralAssets](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[AcquisitionCost_Amount] [decimal](16, 2) NULL,
	[AcquisitionCost_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[IsNewlyAdded] [bit] NOT NULL,
	[IsFromProgressFunding] [bit] NOT NULL,
	[IsPrimary] [bit] NOT NULL,
	[TerminationDate] [date] NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[AssetId] [bigint] NULL,
	[LoanFinanceId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CollateralAssets]  WITH CHECK ADD  CONSTRAINT [ECollateralAsset_Asset] FOREIGN KEY([AssetId])
REFERENCES [dbo].[Assets] ([Id])
GO
ALTER TABLE [dbo].[CollateralAssets] CHECK CONSTRAINT [ECollateralAsset_Asset]
GO
ALTER TABLE [dbo].[CollateralAssets]  WITH CHECK ADD  CONSTRAINT [ELoanFinance_CollateralAssets] FOREIGN KEY([LoanFinanceId])
REFERENCES [dbo].[LoanFinances] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CollateralAssets] CHECK CONSTRAINT [ELoanFinance_CollateralAssets]
GO
