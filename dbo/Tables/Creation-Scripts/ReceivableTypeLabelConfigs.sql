SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ReceivableTypeLabelConfigs](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[IsDefault] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[InvoiceGroupingParameterId] [bigint] NULL,
	[ReceivableCategoryId] [bigint] NOT NULL,
	[ReceivableTypeId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[PortfolioId] [bigint] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ReceivableTypeLabelConfigs]  WITH CHECK ADD  CONSTRAINT [EReceivableTypeLabelConfig_InvoiceGroupingParameter] FOREIGN KEY([InvoiceGroupingParameterId])
REFERENCES [dbo].[InvoiceGroupingParameters] ([Id])
GO
ALTER TABLE [dbo].[ReceivableTypeLabelConfigs] CHECK CONSTRAINT [EReceivableTypeLabelConfig_InvoiceGroupingParameter]
GO
ALTER TABLE [dbo].[ReceivableTypeLabelConfigs]  WITH CHECK ADD  CONSTRAINT [EReceivableTypeLabelConfig_Portfolio] FOREIGN KEY([PortfolioId])
REFERENCES [dbo].[Portfolios] ([Id])
GO
ALTER TABLE [dbo].[ReceivableTypeLabelConfigs] CHECK CONSTRAINT [EReceivableTypeLabelConfig_Portfolio]
GO
ALTER TABLE [dbo].[ReceivableTypeLabelConfigs]  WITH CHECK ADD  CONSTRAINT [EReceivableTypeLabelConfig_ReceivableCategory] FOREIGN KEY([ReceivableCategoryId])
REFERENCES [dbo].[ReceivableCategories] ([Id])
GO
ALTER TABLE [dbo].[ReceivableTypeLabelConfigs] CHECK CONSTRAINT [EReceivableTypeLabelConfig_ReceivableCategory]
GO
ALTER TABLE [dbo].[ReceivableTypeLabelConfigs]  WITH CHECK ADD  CONSTRAINT [EReceivableTypeLabelConfig_ReceivableType] FOREIGN KEY([ReceivableTypeId])
REFERENCES [dbo].[ReceivableTypes] ([Id])
GO
ALTER TABLE [dbo].[ReceivableTypeLabelConfigs] CHECK CONSTRAINT [EReceivableTypeLabelConfig_ReceivableType]
GO
