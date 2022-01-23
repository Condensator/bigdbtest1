SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CreditBureauConfigs](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[Name] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[Code] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[SupportedCountry] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[IsBusinessBureau] [bit] NOT NULL,
	[CreditBureauIntegrationConfigId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CreditBureauConfigs]  WITH CHECK ADD  CONSTRAINT [ECreditBureauConfig_CreditBureauIntegrationConfig] FOREIGN KEY([CreditBureauIntegrationConfigId])
REFERENCES [dbo].[CreditBureauIntegrationConfigs] ([Id])
GO
ALTER TABLE [dbo].[CreditBureauConfigs] CHECK CONSTRAINT [ECreditBureauConfig_CreditBureauIntegrationConfig]
GO
