SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CreditBureauErrorMessageConfigs](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Code] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[Description] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[ErrorType] [nvarchar](11) COLLATE Latin1_General_CI_AS NULL,
	[CreditBureauDirectConfigId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[PortfolioId] [bigint] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CreditBureauErrorMessageConfigs]  WITH CHECK ADD  CONSTRAINT [ECreditBureauErrorMessageConfig_CreditBureauDirectConfig] FOREIGN KEY([CreditBureauDirectConfigId])
REFERENCES [dbo].[CreditBureauDirectConfigs] ([Id])
GO
ALTER TABLE [dbo].[CreditBureauErrorMessageConfigs] CHECK CONSTRAINT [ECreditBureauErrorMessageConfig_CreditBureauDirectConfig]
GO
ALTER TABLE [dbo].[CreditBureauErrorMessageConfigs]  WITH CHECK ADD  CONSTRAINT [ECreditBureauErrorMessageConfig_Portfolio] FOREIGN KEY([PortfolioId])
REFERENCES [dbo].[Portfolios] ([Id])
GO
ALTER TABLE [dbo].[CreditBureauErrorMessageConfigs] CHECK CONSTRAINT [ECreditBureauErrorMessageConfig_Portfolio]
GO
