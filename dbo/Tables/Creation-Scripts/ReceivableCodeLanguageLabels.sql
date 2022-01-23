SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ReceivableCodeLanguageLabels](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[InvoiceLabel] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ReceivableCodeId] [bigint] NOT NULL,
	[LanguageConfigId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ReceivableCodeLanguageLabels]  WITH CHECK ADD  CONSTRAINT [EReceivableCode_ReceivableCodeLanguageLabels] FOREIGN KEY([ReceivableCodeId])
REFERENCES [dbo].[ReceivableCodes] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[ReceivableCodeLanguageLabels] CHECK CONSTRAINT [EReceivableCode_ReceivableCodeLanguageLabels]
GO
ALTER TABLE [dbo].[ReceivableCodeLanguageLabels]  WITH CHECK ADD  CONSTRAINT [EReceivableCodeLanguageLabel_LanguageConfig] FOREIGN KEY([LanguageConfigId])
REFERENCES [dbo].[LanguageConfigs] ([Id])
GO
ALTER TABLE [dbo].[ReceivableCodeLanguageLabels] CHECK CONSTRAINT [EReceivableCodeLanguageLabel_LanguageConfig]
GO
