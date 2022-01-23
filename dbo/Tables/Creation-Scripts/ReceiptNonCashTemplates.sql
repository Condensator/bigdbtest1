SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ReceiptNonCashTemplates](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[NonCashTypeId] [bigint] NOT NULL,
	[GLTemplateId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ReceiptNonCashTemplates]  WITH CHECK ADD  CONSTRAINT [EReceiptNonCashTemplate_GLTemplate] FOREIGN KEY([GLTemplateId])
REFERENCES [dbo].[GLTemplates] ([Id])
GO
ALTER TABLE [dbo].[ReceiptNonCashTemplates] CHECK CONSTRAINT [EReceiptNonCashTemplate_GLTemplate]
GO
ALTER TABLE [dbo].[ReceiptNonCashTemplates]  WITH CHECK ADD  CONSTRAINT [EReceiptNonCashTemplate_NonCashType] FOREIGN KEY([NonCashTypeId])
REFERENCES [dbo].[ReceiptTypes] ([Id])
GO
ALTER TABLE [dbo].[ReceiptNonCashTemplates] CHECK CONSTRAINT [EReceiptNonCashTemplate_NonCashType]
GO
