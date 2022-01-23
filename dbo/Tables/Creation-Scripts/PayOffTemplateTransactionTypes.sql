SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PayOffTemplateTransactionTypes](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[TransactionTypeId] [bigint] NULL,
	[PayOffTemplateId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[PayOffTemplateTransactionTypes]  WITH CHECK ADD  CONSTRAINT [EPayOffTemplate_PayOffTemplateTransactionTypes] FOREIGN KEY([PayOffTemplateId])
REFERENCES [dbo].[PayOffTemplates] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[PayOffTemplateTransactionTypes] CHECK CONSTRAINT [EPayOffTemplate_PayOffTemplateTransactionTypes]
GO
ALTER TABLE [dbo].[PayOffTemplateTransactionTypes]  WITH CHECK ADD  CONSTRAINT [EPayOffTemplateTransactionType_TransactionType] FOREIGN KEY([TransactionTypeId])
REFERENCES [dbo].[DealProductTypes] ([Id])
GO
ALTER TABLE [dbo].[PayOffTemplateTransactionTypes] CHECK CONSTRAINT [EPayOffTemplateTransactionType_TransactionType]
GO
