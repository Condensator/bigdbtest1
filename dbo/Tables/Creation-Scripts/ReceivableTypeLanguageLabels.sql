SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ReceivableTypeLanguageLabels](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[InvoiceLabel] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ReceivableTypeLabelConfigId] [bigint] NOT NULL,
	[LanguageConfigId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[PortfolioId] [bigint] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ReceivableTypeLanguageLabels]  WITH CHECK ADD  CONSTRAINT [EReceivableTypeLabelConfig_ReceivableTypeLanguageLabels] FOREIGN KEY([ReceivableTypeLabelConfigId])
REFERENCES [dbo].[ReceivableTypeLabelConfigs] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[ReceivableTypeLanguageLabels] CHECK CONSTRAINT [EReceivableTypeLabelConfig_ReceivableTypeLanguageLabels]
GO
ALTER TABLE [dbo].[ReceivableTypeLanguageLabels]  WITH CHECK ADD  CONSTRAINT [EReceivableTypeLanguageLabel_LanguageConfig] FOREIGN KEY([LanguageConfigId])
REFERENCES [dbo].[LanguageConfigs] ([Id])
GO
ALTER TABLE [dbo].[ReceivableTypeLanguageLabels] CHECK CONSTRAINT [EReceivableTypeLanguageLabel_LanguageConfig]
GO
ALTER TABLE [dbo].[ReceivableTypeLanguageLabels]  WITH CHECK ADD  CONSTRAINT [EReceivableTypeLanguageLabel_Portfolio] FOREIGN KEY([PortfolioId])
REFERENCES [dbo].[Portfolios] ([Id])
GO
ALTER TABLE [dbo].[ReceivableTypeLanguageLabels] CHECK CONSTRAINT [EReceivableTypeLanguageLabel_Portfolio]
GO
