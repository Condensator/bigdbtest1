SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LoanAmendments](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[QuoteName] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[AmendmentType] [nvarchar](31) COLLATE Latin1_General_CI_AS NOT NULL,
	[QuoteStatus] [nvarchar](9) COLLATE Latin1_General_CI_AS NOT NULL,
	[AmendmentDate] [date] NULL,
	[AccountingDate] [date] NULL,
	[QuoteGoodThroughDate] [date] NULL,
	[Comment] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[PostDate] [date] NULL,
	[IsTDR] [bit] NOT NULL,
	[AmendmentAtInception] [bit] NOT NULL,
	[ReceivableAmendmentType] [nvarchar](20) COLLATE Latin1_General_CI_AS NULL,
	[IsRestructureDateConfirmed] [bit] NOT NULL,
	[TDRReason] [nvarchar](24) COLLATE Latin1_General_CI_AS NULL,
	[FinalAcceptanceDate] [date] NULL,
	[IsLienFilingRequired] [bit] NOT NULL,
	[IsLienFilingException] [bit] NOT NULL,
	[LienExceptionComment] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[LienExceptionReason] [nvarchar](24) COLLATE Latin1_General_CI_AS NULL,
	[PreRestructureDateLoanNBV_Amount] [decimal](16, 2) NOT NULL,
	[PreRestructureDateLoanNBV_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[PostRestructureDateLoanNBV_Amount] [decimal](16, 2) NOT NULL,
	[PostRestructureDateLoanNBV_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[PreRestructureFAS91Balance_Amount] [decimal](16, 2) NOT NULL,
	[PreRestructureFAS91Balance_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[PostRestructureFAS91Balance_Amount] [decimal](16, 2) NOT NULL,
	[PostRestructureFAS91Balance_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[NetWritedown_Amount] [decimal](16, 2) NOT NULL,
	[NetWritedown_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsModified] [bit] NOT NULL,
	[SourceId] [bigint] NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[LoanFinanceId] [bigint] NOT NULL,
	[LoanPaymentScheduleId] [bigint] NULL,
	[DealProductTypeId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[DealTypeId] [bigint] NULL,
	[AmendmentReasonId] [bigint] NULL,
	[AmendmentReasonComment] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[LoanAmendments]  WITH CHECK ADD  CONSTRAINT [ELoanAmendment_AmendmentReason] FOREIGN KEY([AmendmentReasonId])
REFERENCES [dbo].[ContractAmendmentReasonCodes] ([Id])
GO
ALTER TABLE [dbo].[LoanAmendments] CHECK CONSTRAINT [ELoanAmendment_AmendmentReason]
GO
ALTER TABLE [dbo].[LoanAmendments]  WITH CHECK ADD  CONSTRAINT [ELoanAmendment_DealProductType] FOREIGN KEY([DealProductTypeId])
REFERENCES [dbo].[DealProductTypes] ([Id])
GO
ALTER TABLE [dbo].[LoanAmendments] CHECK CONSTRAINT [ELoanAmendment_DealProductType]
GO
ALTER TABLE [dbo].[LoanAmendments]  WITH CHECK ADD  CONSTRAINT [ELoanAmendment_DealType] FOREIGN KEY([DealTypeId])
REFERENCES [dbo].[DealTypes] ([Id])
GO
ALTER TABLE [dbo].[LoanAmendments] CHECK CONSTRAINT [ELoanAmendment_DealType]
GO
ALTER TABLE [dbo].[LoanAmendments]  WITH CHECK ADD  CONSTRAINT [ELoanAmendment_LoanFinance] FOREIGN KEY([LoanFinanceId])
REFERENCES [dbo].[LoanFinances] ([Id])
GO
ALTER TABLE [dbo].[LoanAmendments] CHECK CONSTRAINT [ELoanAmendment_LoanFinance]
GO
ALTER TABLE [dbo].[LoanAmendments]  WITH CHECK ADD  CONSTRAINT [ELoanAmendment_LoanPaymentSchedule] FOREIGN KEY([LoanPaymentScheduleId])
REFERENCES [dbo].[LoanPaymentSchedules] ([Id])
GO
ALTER TABLE [dbo].[LoanAmendments] CHECK CONSTRAINT [ELoanAmendment_LoanPaymentSchedule]
GO
