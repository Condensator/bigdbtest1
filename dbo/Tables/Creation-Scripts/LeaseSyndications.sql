SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LeaseSyndications](
	[Id] [bigint] NOT NULL,
	[RetainedPercentage] [decimal](18, 8) NULL,
	[FundedAmount_Amount] [decimal](16, 2) NOT NULL,
	[FundedAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RentalProceedsPayableCodeId] [bigint] NULL,
	[ProgressPaymentReimbursementCodeId] [bigint] NULL,
	[ScrapeReceivableCodeId] [bigint] NULL,
	[UpfrontSyndicationFeeCodeId] [bigint] NULL,
	[LoanPaydownGLTemplateId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[FundingDate] [date] NULL,
	[RentalProceedsWithholdingTaxRate] [decimal](5, 2) NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[LeaseSyndications]  WITH CHECK ADD  CONSTRAINT [ELeaseFinance_LeaseSyndication] FOREIGN KEY([Id])
REFERENCES [dbo].[LeaseFinances] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[LeaseSyndications] CHECK CONSTRAINT [ELeaseFinance_LeaseSyndication]
GO
ALTER TABLE [dbo].[LeaseSyndications]  WITH CHECK ADD  CONSTRAINT [ELeaseSyndication_LoanPaydownGLTemplate] FOREIGN KEY([LoanPaydownGLTemplateId])
REFERENCES [dbo].[GLTemplates] ([Id])
GO
ALTER TABLE [dbo].[LeaseSyndications] CHECK CONSTRAINT [ELeaseSyndication_LoanPaydownGLTemplate]
GO
ALTER TABLE [dbo].[LeaseSyndications]  WITH CHECK ADD  CONSTRAINT [ELeaseSyndication_ProgressPaymentReimbursementCode] FOREIGN KEY([ProgressPaymentReimbursementCodeId])
REFERENCES [dbo].[ReceivableCodes] ([Id])
GO
ALTER TABLE [dbo].[LeaseSyndications] CHECK CONSTRAINT [ELeaseSyndication_ProgressPaymentReimbursementCode]
GO
ALTER TABLE [dbo].[LeaseSyndications]  WITH CHECK ADD  CONSTRAINT [ELeaseSyndication_RentalProceedsPayableCode] FOREIGN KEY([RentalProceedsPayableCodeId])
REFERENCES [dbo].[PayableCodes] ([Id])
GO
ALTER TABLE [dbo].[LeaseSyndications] CHECK CONSTRAINT [ELeaseSyndication_RentalProceedsPayableCode]
GO
ALTER TABLE [dbo].[LeaseSyndications]  WITH CHECK ADD  CONSTRAINT [ELeaseSyndication_ScrapeReceivableCode] FOREIGN KEY([ScrapeReceivableCodeId])
REFERENCES [dbo].[ReceivableCodes] ([Id])
GO
ALTER TABLE [dbo].[LeaseSyndications] CHECK CONSTRAINT [ELeaseSyndication_ScrapeReceivableCode]
GO
ALTER TABLE [dbo].[LeaseSyndications]  WITH CHECK ADD  CONSTRAINT [ELeaseSyndication_UpfrontSyndicationFeeCode] FOREIGN KEY([UpfrontSyndicationFeeCodeId])
REFERENCES [dbo].[BlendedItemCodes] ([Id])
GO
ALTER TABLE [dbo].[LeaseSyndications] CHECK CONSTRAINT [ELeaseSyndication_UpfrontSyndicationFeeCode]
GO
