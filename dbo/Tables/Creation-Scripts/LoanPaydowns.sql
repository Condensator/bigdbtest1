SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LoanPaydowns](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[QuoteName] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[PaydownDate] [date] NULL,
	[PaydownReason] [nvarchar](30) COLLATE Latin1_General_CI_AS NOT NULL,
	[PaydownAmortOption] [nvarchar](17) COLLATE Latin1_General_CI_AS NULL,
	[GoodThroughDate] [date] NULL,
	[AmortProcessThroughDate] [date] NULL,
	[ReceivableAmendmentType] [nvarchar](20) COLLATE Latin1_General_CI_AS NOT NULL,
	[Status] [nvarchar](9) COLLATE Latin1_General_CI_AS NOT NULL,
	[AccountingDate] [date] NULL,
	[PostDate] [date] NULL,
	[Comment] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[InvoiceDate] [date] NULL,
	[DueDate] [date] NULL,
	[PrincipalPaydown_Amount] [decimal](16, 2) NULL,
	[PrincipalPaydown_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[InterestPaydown_Amount] [decimal](16, 2) NULL,
	[InterestPaydown_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[NumberOfPayments] [int] NULL,
	[IsPaymentScheduleGenerated] [bit] NOT NULL,
	[IsPaymentModified] [bit] NOT NULL,
	[IsPaymentScheduleCleared] [bit] NOT NULL,
	[InvoiceFile_Source] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[InvoiceFile_Type] [nvarchar](5) COLLATE Latin1_General_CI_AS NULL,
	[InvoiceFile_Content] [varbinary](82) NULL,
	[PrincipalOutstanding_Amount] [decimal](16, 2) NULL,
	[PrincipalOutstanding_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[InterestOutstanding_Amount] [decimal](16, 2) NULL,
	[InterestOutstanding_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[PrincipalBalance_Amount] [decimal](16, 2) NULL,
	[PrincipalBalance_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[AccruedInterest_Amount] [decimal](16, 2) NULL,
	[AccruedInterest_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[RecoveryAtPaydown_Amount] [decimal](16, 2) NOT NULL,
	[RecoveryAtPaydown_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[WritedownAtPaydown_Amount] [decimal](16, 2) NOT NULL,
	[WritedownAtPaydown_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[UnrecoveredWritedownAtPaydown_Amount] [decimal](16, 2) NOT NULL,
	[UnrecoveredWritedownAtPaydown_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[NetWritedown_Amount] [decimal](16, 2) NOT NULL,
	[NetWritedown_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsPaydownFromLoan] [bit] NOT NULL,
	[Settlement] [bit] NOT NULL,
	[Report1099C] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[LoanFinanceId] [bigint] NOT NULL,
	[LoanPaymentId] [bigint] NULL,
	[LoanAmendmentId] [bigint] NULL,
	[BillToId] [bigint] NULL,
	[RemitToId] [bigint] NULL,
	[PaydownGLTemplateId] [bigint] NULL,
	[PrincipalPaydownReceivableCodeId] [bigint] NULL,
	[InterestPaydownReceivableCodeId] [bigint] NULL,
	[WritedownGLTemplateId] [bigint] NULL,
	[RecoveryGLTemplateId] [bigint] NULL,
	[RecoveryReceivableCodeId] [bigint] NULL,
	[CasualtyReceivableCodeId] [bigint] NULL,
	[InvoiceId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[PaydownAtInception] [bit] NOT NULL,
	[ReceiptId] [bigint] NULL,
	[PrepaymentPenaltyReceivableCodeId] [bigint] NULL,
	[PrepaymentPenalty_Amount] [decimal](16, 2) NULL,
	[PrepaymentPenalty_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[InterestRate] [decimal](10, 6) NOT NULL,
	[GainLoss_Amount] [decimal](16, 2) NOT NULL,
	[GainLoss_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[AssetHoldingStatusChangeId] [bigint] NULL,
	[PaydownRequestPhoneNumber] [nvarchar](15) COLLATE Latin1_General_CI_AS NULL,
	[PaydownRequestEMail] [nvarchar](70) COLLATE Latin1_General_CI_AS NULL,
	[QuoteNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[DisbursementId] [bigint] NULL,
	[CustomerId] [bigint] NULL,
	[IsSystemGenerated] [bit] NOT NULL,
	[PaydownTemplateId] [bigint] NULL,
	[DailyFinanceAsOfDate] [date] NULL,
	[IsPaydownTemplateParametersChanged] [bit] NOT NULL,
	[SuggestedPaydownAmount_Amount] [decimal](16, 2) NOT NULL,
	[SuggestedPaydownAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsPaydownPricingOptionsPopulated] [bit] NOT NULL,
	[ExcessPaydownAmount] [decimal](16, 2) NOT NULL,
	[SundryReceivableCodeId] [bigint] NULL,
	[CloseRevolvingLoan] [bit] NOT NULL,
	[InvoicePreference] [nvarchar](18) COLLATE Latin1_General_CI_AS NOT NULL,
	[IncludeOutstandingCharges] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[LoanPaydowns]  WITH CHECK ADD  CONSTRAINT [ELoanPaydown_AssetHoldingStatusChange] FOREIGN KEY([AssetHoldingStatusChangeId])
REFERENCES [dbo].[AssetHoldingStatusChanges] ([Id])
GO
ALTER TABLE [dbo].[LoanPaydowns] CHECK CONSTRAINT [ELoanPaydown_AssetHoldingStatusChange]
GO
ALTER TABLE [dbo].[LoanPaydowns]  WITH CHECK ADD  CONSTRAINT [ELoanPaydown_BillTo] FOREIGN KEY([BillToId])
REFERENCES [dbo].[BillToes] ([Id])
GO
ALTER TABLE [dbo].[LoanPaydowns] CHECK CONSTRAINT [ELoanPaydown_BillTo]
GO
ALTER TABLE [dbo].[LoanPaydowns]  WITH CHECK ADD  CONSTRAINT [ELoanPaydown_CasualtyReceivableCode] FOREIGN KEY([CasualtyReceivableCodeId])
REFERENCES [dbo].[ReceivableCodes] ([Id])
GO
ALTER TABLE [dbo].[LoanPaydowns] CHECK CONSTRAINT [ELoanPaydown_CasualtyReceivableCode]
GO
ALTER TABLE [dbo].[LoanPaydowns]  WITH CHECK ADD  CONSTRAINT [ELoanPaydown_Customer] FOREIGN KEY([CustomerId])
REFERENCES [dbo].[Customers] ([Id])
GO
ALTER TABLE [dbo].[LoanPaydowns] CHECK CONSTRAINT [ELoanPaydown_Customer]
GO
ALTER TABLE [dbo].[LoanPaydowns]  WITH CHECK ADD  CONSTRAINT [ELoanPaydown_Disbursement] FOREIGN KEY([DisbursementId])
REFERENCES [dbo].[PayableInvoiceOtherCosts] ([Id])
GO
ALTER TABLE [dbo].[LoanPaydowns] CHECK CONSTRAINT [ELoanPaydown_Disbursement]
GO
ALTER TABLE [dbo].[LoanPaydowns]  WITH CHECK ADD  CONSTRAINT [ELoanPaydown_InterestPaydownReceivableCode] FOREIGN KEY([InterestPaydownReceivableCodeId])
REFERENCES [dbo].[ReceivableCodes] ([Id])
GO
ALTER TABLE [dbo].[LoanPaydowns] CHECK CONSTRAINT [ELoanPaydown_InterestPaydownReceivableCode]
GO
ALTER TABLE [dbo].[LoanPaydowns]  WITH CHECK ADD  CONSTRAINT [ELoanPaydown_Invoice] FOREIGN KEY([InvoiceId])
REFERENCES [dbo].[ReceivableInvoices] ([Id])
GO
ALTER TABLE [dbo].[LoanPaydowns] CHECK CONSTRAINT [ELoanPaydown_Invoice]
GO
ALTER TABLE [dbo].[LoanPaydowns]  WITH CHECK ADD  CONSTRAINT [ELoanPaydown_LoanAmendment] FOREIGN KEY([LoanAmendmentId])
REFERENCES [dbo].[LoanAmendments] ([Id])
GO
ALTER TABLE [dbo].[LoanPaydowns] CHECK CONSTRAINT [ELoanPaydown_LoanAmendment]
GO
ALTER TABLE [dbo].[LoanPaydowns]  WITH CHECK ADD  CONSTRAINT [ELoanPaydown_LoanFinance] FOREIGN KEY([LoanFinanceId])
REFERENCES [dbo].[LoanFinances] ([Id])
GO
ALTER TABLE [dbo].[LoanPaydowns] CHECK CONSTRAINT [ELoanPaydown_LoanFinance]
GO
ALTER TABLE [dbo].[LoanPaydowns]  WITH CHECK ADD  CONSTRAINT [ELoanPaydown_LoanPayment] FOREIGN KEY([LoanPaymentId])
REFERENCES [dbo].[LoanPaymentSchedules] ([Id])
GO
ALTER TABLE [dbo].[LoanPaydowns] CHECK CONSTRAINT [ELoanPaydown_LoanPayment]
GO
ALTER TABLE [dbo].[LoanPaydowns]  WITH CHECK ADD  CONSTRAINT [ELoanPaydown_PaydownGLTemplate] FOREIGN KEY([PaydownGLTemplateId])
REFERENCES [dbo].[GLTemplates] ([Id])
GO
ALTER TABLE [dbo].[LoanPaydowns] CHECK CONSTRAINT [ELoanPaydown_PaydownGLTemplate]
GO
ALTER TABLE [dbo].[LoanPaydowns]  WITH CHECK ADD  CONSTRAINT [ELoanPaydown_PaydownTemplate] FOREIGN KEY([PaydownTemplateId])
REFERENCES [dbo].[Paydowntemplates] ([Id])
GO
ALTER TABLE [dbo].[LoanPaydowns] CHECK CONSTRAINT [ELoanPaydown_PaydownTemplate]
GO
ALTER TABLE [dbo].[LoanPaydowns]  WITH CHECK ADD  CONSTRAINT [ELoanPaydown_PrepaymentPenaltyReceivableCode] FOREIGN KEY([PrepaymentPenaltyReceivableCodeId])
REFERENCES [dbo].[ReceivableCodes] ([Id])
GO
ALTER TABLE [dbo].[LoanPaydowns] CHECK CONSTRAINT [ELoanPaydown_PrepaymentPenaltyReceivableCode]
GO
ALTER TABLE [dbo].[LoanPaydowns]  WITH CHECK ADD  CONSTRAINT [ELoanPaydown_PrincipalPaydownReceivableCode] FOREIGN KEY([PrincipalPaydownReceivableCodeId])
REFERENCES [dbo].[ReceivableCodes] ([Id])
GO
ALTER TABLE [dbo].[LoanPaydowns] CHECK CONSTRAINT [ELoanPaydown_PrincipalPaydownReceivableCode]
GO
ALTER TABLE [dbo].[LoanPaydowns]  WITH CHECK ADD  CONSTRAINT [ELoanPaydown_Receipt] FOREIGN KEY([ReceiptId])
REFERENCES [dbo].[Receipts] ([Id])
GO
ALTER TABLE [dbo].[LoanPaydowns] CHECK CONSTRAINT [ELoanPaydown_Receipt]
GO
ALTER TABLE [dbo].[LoanPaydowns]  WITH CHECK ADD  CONSTRAINT [ELoanPaydown_RecoveryGLTemplate] FOREIGN KEY([RecoveryGLTemplateId])
REFERENCES [dbo].[GLTemplates] ([Id])
GO
ALTER TABLE [dbo].[LoanPaydowns] CHECK CONSTRAINT [ELoanPaydown_RecoveryGLTemplate]
GO
ALTER TABLE [dbo].[LoanPaydowns]  WITH CHECK ADD  CONSTRAINT [ELoanPaydown_RecoveryReceivableCode] FOREIGN KEY([RecoveryReceivableCodeId])
REFERENCES [dbo].[ReceivableCodes] ([Id])
GO
ALTER TABLE [dbo].[LoanPaydowns] CHECK CONSTRAINT [ELoanPaydown_RecoveryReceivableCode]
GO
ALTER TABLE [dbo].[LoanPaydowns]  WITH CHECK ADD  CONSTRAINT [ELoanPaydown_RemitTo] FOREIGN KEY([RemitToId])
REFERENCES [dbo].[RemitToes] ([Id])
GO
ALTER TABLE [dbo].[LoanPaydowns] CHECK CONSTRAINT [ELoanPaydown_RemitTo]
GO
ALTER TABLE [dbo].[LoanPaydowns]  WITH CHECK ADD  CONSTRAINT [ELoanPaydown_SundryReceivableCode] FOREIGN KEY([SundryReceivableCodeId])
REFERENCES [dbo].[ReceivableCodes] ([Id])
GO
ALTER TABLE [dbo].[LoanPaydowns] CHECK CONSTRAINT [ELoanPaydown_SundryReceivableCode]
GO
ALTER TABLE [dbo].[LoanPaydowns]  WITH CHECK ADD  CONSTRAINT [ELoanPaydown_WritedownGLTemplate] FOREIGN KEY([WritedownGLTemplateId])
REFERENCES [dbo].[GLTemplates] ([Id])
GO
ALTER TABLE [dbo].[LoanPaydowns] CHECK CONSTRAINT [ELoanPaydown_WritedownGLTemplate]
GO
