SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PreQuoteCollateralAssets](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[AssetId] [bigint] NOT NULL,
	[PreQuoteLoanId] [bigint] NOT NULL,
	[PreQuoteId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[PreQuoteCollateralAssets]  WITH CHECK ADD  CONSTRAINT [EPreQuote_PreQuoteCollateralAssets] FOREIGN KEY([PreQuoteId])
REFERENCES [dbo].[PreQuotes] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[PreQuoteCollateralAssets] CHECK CONSTRAINT [EPreQuote_PreQuoteCollateralAssets]
GO
ALTER TABLE [dbo].[PreQuoteCollateralAssets]  WITH CHECK ADD  CONSTRAINT [EPreQuoteCollateralAsset_Asset] FOREIGN KEY([AssetId])
REFERENCES [dbo].[Assets] ([Id])
GO
ALTER TABLE [dbo].[PreQuoteCollateralAssets] CHECK CONSTRAINT [EPreQuoteCollateralAsset_Asset]
GO
ALTER TABLE [dbo].[PreQuoteCollateralAssets]  WITH CHECK ADD  CONSTRAINT [EPreQuoteCollateralAsset_PreQuoteLoan] FOREIGN KEY([PreQuoteLoanId])
REFERENCES [dbo].[PreQuoteLoans] ([Id])
GO
ALTER TABLE [dbo].[PreQuoteCollateralAssets] CHECK CONSTRAINT [EPreQuoteCollateralAsset_PreQuoteLoan]
GO
