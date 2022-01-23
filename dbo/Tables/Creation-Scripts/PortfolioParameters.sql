SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PortfolioParameters](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Value] [nvarchar](1000) COLLATE Latin1_General_CI_AS NOT NULL,
	[PortfolioParameterConfigId] [bigint] NOT NULL,
	[PortfolioId] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[PortfolioParameters]  WITH CHECK ADD  CONSTRAINT [EPortfolio_PortfolioParameters] FOREIGN KEY([PortfolioId])
REFERENCES [dbo].[Portfolios] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[PortfolioParameters] CHECK CONSTRAINT [EPortfolio_PortfolioParameters]
GO
ALTER TABLE [dbo].[PortfolioParameters]  WITH CHECK ADD  CONSTRAINT [EPortfolioParameter_PortfolioParameterConfig] FOREIGN KEY([PortfolioParameterConfigId])
REFERENCES [dbo].[PortfolioParameterConfigs] ([Id])
GO
ALTER TABLE [dbo].[PortfolioParameters] CHECK CONSTRAINT [EPortfolioParameter_PortfolioParameterConfig]
GO
