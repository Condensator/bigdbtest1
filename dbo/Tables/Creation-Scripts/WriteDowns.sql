SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[WriteDowns](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[WriteDownDate] [date] NOT NULL,
	[WriteDownAmount_Amount] [decimal](16, 2) NULL,
	[WriteDownAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[IsAssetWriteDown] [bit] NOT NULL,
	[IsRecovery] [bit] NOT NULL,
	[PostDate] [date] NULL,
	[ContractType] [nvarchar](14) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[Status] [nvarchar](20) COLLATE Latin1_General_CI_AS NOT NULL,
	[Comment] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[NetInvestmentWithBlended_Amount] [decimal](16, 2) NOT NULL,
	[NetInvestmentWithBlended_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[NetInvestmentWithReserve_Amount] [decimal](16, 2) NOT NULL,
	[NetInvestmentWithReserve_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[GrossWritedown_Amount] [decimal](16, 2) NOT NULL,
	[GrossWritedown_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[NetWritedown_Amount] [decimal](16, 2) NOT NULL,
	[NetWritedown_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[SourceId] [bigint] NOT NULL,
	[SourceModule] [nvarchar](11) COLLATE Latin1_General_CI_AS NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[GLTemplateId] [bigint] NOT NULL,
	[RecoveryGLTemplateId] [bigint] NULL,
	[RecoveryReceivableCodeId] [bigint] NULL,
	[ContractId] [bigint] NOT NULL,
	[LeaseFinanceId] [bigint] NULL,
	[LoanFinanceId] [bigint] NULL,
	[WriteDownGLJournalId] [bigint] NULL,
	[ReceiptId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[WriteDownReason] [nvarchar](18) COLLATE Latin1_General_CI_AS NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[WriteDowns]  WITH CHECK ADD  CONSTRAINT [EWriteDown_Contract] FOREIGN KEY([ContractId])
REFERENCES [dbo].[Contracts] ([Id])
GO
ALTER TABLE [dbo].[WriteDowns] CHECK CONSTRAINT [EWriteDown_Contract]
GO
ALTER TABLE [dbo].[WriteDowns]  WITH CHECK ADD  CONSTRAINT [EWriteDown_GLTemplate] FOREIGN KEY([GLTemplateId])
REFERENCES [dbo].[GLTemplates] ([Id])
GO
ALTER TABLE [dbo].[WriteDowns] CHECK CONSTRAINT [EWriteDown_GLTemplate]
GO
ALTER TABLE [dbo].[WriteDowns]  WITH CHECK ADD  CONSTRAINT [EWriteDown_LeaseFinance] FOREIGN KEY([LeaseFinanceId])
REFERENCES [dbo].[LeaseFinances] ([Id])
GO
ALTER TABLE [dbo].[WriteDowns] CHECK CONSTRAINT [EWriteDown_LeaseFinance]
GO
ALTER TABLE [dbo].[WriteDowns]  WITH CHECK ADD  CONSTRAINT [EWriteDown_LoanFinance] FOREIGN KEY([LoanFinanceId])
REFERENCES [dbo].[LoanFinances] ([Id])
GO
ALTER TABLE [dbo].[WriteDowns] CHECK CONSTRAINT [EWriteDown_LoanFinance]
GO
ALTER TABLE [dbo].[WriteDowns]  WITH CHECK ADD  CONSTRAINT [EWriteDown_Receipt] FOREIGN KEY([ReceiptId])
REFERENCES [dbo].[Receipts] ([Id])
GO
ALTER TABLE [dbo].[WriteDowns] CHECK CONSTRAINT [EWriteDown_Receipt]
GO
ALTER TABLE [dbo].[WriteDowns]  WITH CHECK ADD  CONSTRAINT [EWriteDown_RecoveryGLTemplate] FOREIGN KEY([RecoveryGLTemplateId])
REFERENCES [dbo].[GLTemplates] ([Id])
GO
ALTER TABLE [dbo].[WriteDowns] CHECK CONSTRAINT [EWriteDown_RecoveryGLTemplate]
GO
ALTER TABLE [dbo].[WriteDowns]  WITH CHECK ADD  CONSTRAINT [EWriteDown_RecoveryReceivableCode] FOREIGN KEY([RecoveryReceivableCodeId])
REFERENCES [dbo].[ReceivableCodes] ([Id])
GO
ALTER TABLE [dbo].[WriteDowns] CHECK CONSTRAINT [EWriteDown_RecoveryReceivableCode]
GO
ALTER TABLE [dbo].[WriteDowns]  WITH CHECK ADD  CONSTRAINT [EWriteDown_WriteDownGLJournal] FOREIGN KEY([WriteDownGLJournalId])
REFERENCES [dbo].[GLJournals] ([Id])
GO
ALTER TABLE [dbo].[WriteDowns] CHECK CONSTRAINT [EWriteDown_WriteDownGLJournal]
GO
