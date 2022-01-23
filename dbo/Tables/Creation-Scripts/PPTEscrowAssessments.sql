SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PPTEscrowAssessments](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[DisposistionAmount_Amount] [decimal](16, 2) NULL,
	[DisposistionAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[PostDate] [date] NULL,
	[EscrowDisposistion] [nvarchar](14) COLLATE Latin1_General_CI_AS NULL,
	[Status] [nvarchar](19) COLLATE Latin1_General_CI_AS NOT NULL,
	[TotalEscrowAmount_Amount] [decimal](16, 2) NULL,
	[TotalEscrowAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[EscrowProcessAmount_Amount] [decimal](16, 2) NULL,
	[EscrowProcessAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[ReceivableDueDate] [date] NULL,
	[PayableDueDate] [date] NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ContractId] [bigint] NOT NULL,
	[ReceivableCodeId] [bigint] NULL,
	[ReceivableRemitToId] [bigint] NULL,
	[PayableCodeId] [bigint] NULL,
	[PayableRemitToId] [bigint] NULL,
	[VendorId] [bigint] NULL,
	[CustomerId] [bigint] NULL,
	[ReceiptNonCashGLTemplateId] [bigint] NULL,
	[ReceiptId] [bigint] NULL,
	[SundryId] [bigint] NULL,
	[GlJournalId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[PayableWithholdingTaxRate] [decimal](5, 2) NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[PPTEscrowAssessments]  WITH CHECK ADD  CONSTRAINT [EPPTEscrowAssessment_Contract] FOREIGN KEY([ContractId])
REFERENCES [dbo].[Contracts] ([Id])
GO
ALTER TABLE [dbo].[PPTEscrowAssessments] CHECK CONSTRAINT [EPPTEscrowAssessment_Contract]
GO
ALTER TABLE [dbo].[PPTEscrowAssessments]  WITH CHECK ADD  CONSTRAINT [EPPTEscrowAssessment_Customer] FOREIGN KEY([CustomerId])
REFERENCES [dbo].[Customers] ([Id])
GO
ALTER TABLE [dbo].[PPTEscrowAssessments] CHECK CONSTRAINT [EPPTEscrowAssessment_Customer]
GO
ALTER TABLE [dbo].[PPTEscrowAssessments]  WITH CHECK ADD  CONSTRAINT [EPPTEscrowAssessment_GlJournal] FOREIGN KEY([GlJournalId])
REFERENCES [dbo].[GLJournals] ([Id])
GO
ALTER TABLE [dbo].[PPTEscrowAssessments] CHECK CONSTRAINT [EPPTEscrowAssessment_GlJournal]
GO
ALTER TABLE [dbo].[PPTEscrowAssessments]  WITH CHECK ADD  CONSTRAINT [EPPTEscrowAssessment_PayableCode] FOREIGN KEY([PayableCodeId])
REFERENCES [dbo].[PayableCodes] ([Id])
GO
ALTER TABLE [dbo].[PPTEscrowAssessments] CHECK CONSTRAINT [EPPTEscrowAssessment_PayableCode]
GO
ALTER TABLE [dbo].[PPTEscrowAssessments]  WITH CHECK ADD  CONSTRAINT [EPPTEscrowAssessment_PayableRemitTo] FOREIGN KEY([PayableRemitToId])
REFERENCES [dbo].[RemitToes] ([Id])
GO
ALTER TABLE [dbo].[PPTEscrowAssessments] CHECK CONSTRAINT [EPPTEscrowAssessment_PayableRemitTo]
GO
ALTER TABLE [dbo].[PPTEscrowAssessments]  WITH CHECK ADD  CONSTRAINT [EPPTEscrowAssessment_Receipt] FOREIGN KEY([ReceiptId])
REFERENCES [dbo].[Receipts] ([Id])
GO
ALTER TABLE [dbo].[PPTEscrowAssessments] CHECK CONSTRAINT [EPPTEscrowAssessment_Receipt]
GO
ALTER TABLE [dbo].[PPTEscrowAssessments]  WITH CHECK ADD  CONSTRAINT [EPPTEscrowAssessment_ReceiptNonCashGLTemplate] FOREIGN KEY([ReceiptNonCashGLTemplateId])
REFERENCES [dbo].[GLTemplates] ([Id])
GO
ALTER TABLE [dbo].[PPTEscrowAssessments] CHECK CONSTRAINT [EPPTEscrowAssessment_ReceiptNonCashGLTemplate]
GO
ALTER TABLE [dbo].[PPTEscrowAssessments]  WITH CHECK ADD  CONSTRAINT [EPPTEscrowAssessment_ReceivableCode] FOREIGN KEY([ReceivableCodeId])
REFERENCES [dbo].[ReceivableCodes] ([Id])
GO
ALTER TABLE [dbo].[PPTEscrowAssessments] CHECK CONSTRAINT [EPPTEscrowAssessment_ReceivableCode]
GO
ALTER TABLE [dbo].[PPTEscrowAssessments]  WITH CHECK ADD  CONSTRAINT [EPPTEscrowAssessment_ReceivableRemitTo] FOREIGN KEY([ReceivableRemitToId])
REFERENCES [dbo].[RemitToes] ([Id])
GO
ALTER TABLE [dbo].[PPTEscrowAssessments] CHECK CONSTRAINT [EPPTEscrowAssessment_ReceivableRemitTo]
GO
ALTER TABLE [dbo].[PPTEscrowAssessments]  WITH CHECK ADD  CONSTRAINT [EPPTEscrowAssessment_Sundry] FOREIGN KEY([SundryId])
REFERENCES [dbo].[Sundries] ([Id])
GO
ALTER TABLE [dbo].[PPTEscrowAssessments] CHECK CONSTRAINT [EPPTEscrowAssessment_Sundry]
GO
ALTER TABLE [dbo].[PPTEscrowAssessments]  WITH CHECK ADD  CONSTRAINT [EPPTEscrowAssessment_Vendor] FOREIGN KEY([VendorId])
REFERENCES [dbo].[Vendors] ([Id])
GO
ALTER TABLE [dbo].[PPTEscrowAssessments] CHECK CONSTRAINT [EPPTEscrowAssessment_Vendor]
GO
