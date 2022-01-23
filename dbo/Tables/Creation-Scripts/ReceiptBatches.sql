SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ReceiptBatches](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[PostDate] [date] NULL,
	[ReceivedDate] [date] NOT NULL,
	[DepositAmount_Amount] [decimal](16, 2) NOT NULL,
	[DepositAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Status] [nvarchar](15) COLLATE Latin1_General_CI_AS NOT NULL,
	[Comment] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[LegalEntityId] [bigint] NOT NULL,
	[ReceiptBatchGLTemplateId] [bigint] NULL,
	[CurrencyId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[IsPartiallyPosted] [bit] NOT NULL,
	[ReceiptAmountAlreadyPosted_Amount] [decimal](16, 2) NOT NULL,
	[ReceiptAmountAlreadyPosted_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ReceiptBatches]  WITH CHECK ADD  CONSTRAINT [EReceiptBatch_Currency] FOREIGN KEY([CurrencyId])
REFERENCES [dbo].[Currencies] ([Id])
GO
ALTER TABLE [dbo].[ReceiptBatches] CHECK CONSTRAINT [EReceiptBatch_Currency]
GO
ALTER TABLE [dbo].[ReceiptBatches]  WITH CHECK ADD  CONSTRAINT [EReceiptBatch_LegalEntity] FOREIGN KEY([LegalEntityId])
REFERENCES [dbo].[LegalEntities] ([Id])
GO
ALTER TABLE [dbo].[ReceiptBatches] CHECK CONSTRAINT [EReceiptBatch_LegalEntity]
GO
ALTER TABLE [dbo].[ReceiptBatches]  WITH CHECK ADD  CONSTRAINT [EReceiptBatch_ReceiptBatchGLTemplate] FOREIGN KEY([ReceiptBatchGLTemplateId])
REFERENCES [dbo].[GLTemplates] ([Id])
GO
ALTER TABLE [dbo].[ReceiptBatches] CHECK CONSTRAINT [EReceiptBatch_ReceiptBatchGLTemplate]
GO
