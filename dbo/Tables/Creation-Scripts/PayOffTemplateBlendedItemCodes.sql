SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PayOffTemplateBlendedItemCodes](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[BlendedItemCodeId] [bigint] NOT NULL,
	[PayOffTemplateTerminationTypeParameterId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[PayOffTemplateBlendedItemCodes]  WITH CHECK ADD  CONSTRAINT [EPayOffTemplateBlendedItemCode_BlendedItemCode] FOREIGN KEY([BlendedItemCodeId])
REFERENCES [dbo].[BlendedItemCodes] ([Id])
GO
ALTER TABLE [dbo].[PayOffTemplateBlendedItemCodes] CHECK CONSTRAINT [EPayOffTemplateBlendedItemCode_BlendedItemCode]
GO
ALTER TABLE [dbo].[PayOffTemplateBlendedItemCodes]  WITH CHECK ADD  CONSTRAINT [EPayOffTemplateTerminationTypeParameter_PayOffTemplateBlendedItemCodes] FOREIGN KEY([PayOffTemplateTerminationTypeParameterId])
REFERENCES [dbo].[PayOffTemplateTerminationTypeParameters] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[PayOffTemplateBlendedItemCodes] CHECK CONSTRAINT [EPayOffTemplateTerminationTypeParameter_PayOffTemplateBlendedItemCodes]
GO
