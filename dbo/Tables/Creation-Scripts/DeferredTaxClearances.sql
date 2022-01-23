SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DeferredTaxClearances](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[ClearedAmount_Amount] [decimal](16, 2) NOT NULL,
	[ClearedAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[ClearedDate] [date] NOT NULL,
	[SourceId] [bigint] NOT NULL,
	[SourceTable] [nvarchar](21) COLLATE Latin1_General_CI_AS NOT NULL,
	[JournalId] [bigint] NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[DeferredTaxId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[Type] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[GLTemplateId] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[DeferredTaxClearances]  WITH CHECK ADD  CONSTRAINT [EDeferredTax_DeferredTaxClearances] FOREIGN KEY([DeferredTaxId])
REFERENCES [dbo].[DeferredTaxes] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[DeferredTaxClearances] CHECK CONSTRAINT [EDeferredTax_DeferredTaxClearances]
GO
ALTER TABLE [dbo].[DeferredTaxClearances]  WITH CHECK ADD  CONSTRAINT [EDeferredTaxClearance_GLTemplate] FOREIGN KEY([GLTemplateId])
REFERENCES [dbo].[GLTemplates] ([Id])
GO
ALTER TABLE [dbo].[DeferredTaxClearances] CHECK CONSTRAINT [EDeferredTaxClearance_GLTemplate]
GO
ALTER TABLE [dbo].[DeferredTaxClearances]  WITH CHECK ADD  CONSTRAINT [EDeferredTaxClearance_Journal] FOREIGN KEY([JournalId])
REFERENCES [dbo].[GLJournals] ([Id])
GO
ALTER TABLE [dbo].[DeferredTaxClearances] CHECK CONSTRAINT [EDeferredTaxClearance_Journal]
GO
