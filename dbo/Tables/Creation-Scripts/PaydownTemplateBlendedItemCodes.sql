SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PaydownTemplateBlendedItemCodes](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[BlendedItemCodeId] [bigint] NULL,
	[PaydownTemplateCalculationParameterId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[PaydownTemplateBlendedItemCodes]  WITH CHECK ADD  CONSTRAINT [EPaydownTemplateBlendedItemCode_BlendedItemCode] FOREIGN KEY([BlendedItemCodeId])
REFERENCES [dbo].[BlendedItemCodes] ([Id])
GO
ALTER TABLE [dbo].[PaydownTemplateBlendedItemCodes] CHECK CONSTRAINT [EPaydownTemplateBlendedItemCode_BlendedItemCode]
GO
ALTER TABLE [dbo].[PaydownTemplateBlendedItemCodes]  WITH CHECK ADD  CONSTRAINT [EPaydownTemplateCalculationParameter_PaydownTemplateBlendedItemCodes] FOREIGN KEY([PaydownTemplateCalculationParameterId])
REFERENCES [dbo].[PaydownTemplateCalculationParameters] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[PaydownTemplateBlendedItemCodes] CHECK CONSTRAINT [EPaydownTemplateCalculationParameter_PaydownTemplateBlendedItemCodes]
GO
