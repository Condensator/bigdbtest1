SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PaydownTemplateSundryCodes](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[SundryCodeId] [bigint] NULL,
	[PaydownTemplateCalculationParameterId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[PaydownTemplateSundryCodes]  WITH CHECK ADD  CONSTRAINT [EPaydownTemplateCalculationParameter_PaydownTemplateSundryCodes] FOREIGN KEY([PaydownTemplateCalculationParameterId])
REFERENCES [dbo].[PaydownTemplateCalculationParameters] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[PaydownTemplateSundryCodes] CHECK CONSTRAINT [EPaydownTemplateCalculationParameter_PaydownTemplateSundryCodes]
GO
ALTER TABLE [dbo].[PaydownTemplateSundryCodes]  WITH CHECK ADD  CONSTRAINT [EPaydownTemplateSundryCode_SundryCode] FOREIGN KEY([SundryCodeId])
REFERENCES [dbo].[ReceivableCodes] ([Id])
GO
ALTER TABLE [dbo].[PaydownTemplateSundryCodes] CHECK CONSTRAINT [EPaydownTemplateSundryCode_SundryCode]
GO
