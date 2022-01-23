SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AcquiredPortfolios](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[Type] [nvarchar](20) COLLATE Latin1_General_CI_AS NOT NULL,
	[AcquisitionDate] [date] NOT NULL,
	[Status] [nvarchar](8) COLLATE Latin1_General_CI_AS NOT NULL,
	[AcquisitionId] [nvarchar](12) COLLATE Latin1_General_CI_AS NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[LegalEntityId] [bigint] NOT NULL,
	[AcquiredFromId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[AcquiredPortfolios]  WITH CHECK ADD  CONSTRAINT [EAcquiredPortfolio_AcquiredFrom] FOREIGN KEY([AcquiredFromId])
REFERENCES [dbo].[Funders] ([Id])
GO
ALTER TABLE [dbo].[AcquiredPortfolios] CHECK CONSTRAINT [EAcquiredPortfolio_AcquiredFrom]
GO
ALTER TABLE [dbo].[AcquiredPortfolios]  WITH CHECK ADD  CONSTRAINT [EAcquiredPortfolio_LegalEntity] FOREIGN KEY([LegalEntityId])
REFERENCES [dbo].[LegalEntities] ([Id])
GO
ALTER TABLE [dbo].[AcquiredPortfolios] CHECK CONSTRAINT [EAcquiredPortfolio_LegalEntity]
GO
