SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AcquiredPortfolioServicingDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ServicingDetailId] [bigint] NOT NULL,
	[AcquiredPortfolioId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[AcquiredPortfolioServicingDetails]  WITH CHECK ADD  CONSTRAINT [EAcquiredPortfolio_AcquiredPortfolioServicingDetails] FOREIGN KEY([AcquiredPortfolioId])
REFERENCES [dbo].[AcquiredPortfolios] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[AcquiredPortfolioServicingDetails] CHECK CONSTRAINT [EAcquiredPortfolio_AcquiredPortfolioServicingDetails]
GO
ALTER TABLE [dbo].[AcquiredPortfolioServicingDetails]  WITH CHECK ADD  CONSTRAINT [EAcquiredPortfolioServicingDetail_ServicingDetail] FOREIGN KEY([ServicingDetailId])
REFERENCES [dbo].[ServicingDetails] ([Id])
GO
ALTER TABLE [dbo].[AcquiredPortfolioServicingDetails] CHECK CONSTRAINT [EAcquiredPortfolioServicingDetail_ServicingDetail]
GO
