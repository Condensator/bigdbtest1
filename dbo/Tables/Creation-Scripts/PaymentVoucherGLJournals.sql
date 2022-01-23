SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PaymentVoucherGLJournals](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[PostDate] [date] NOT NULL,
	[IsReversal] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[GLJournalId] [bigint] NOT NULL,
	[PaymentVoucherId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[PaymentVoucherGLJournals]  WITH CHECK ADD  CONSTRAINT [EPaymentVoucher_PaymentVoucherGLJournals] FOREIGN KEY([PaymentVoucherId])
REFERENCES [dbo].[PaymentVouchers] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[PaymentVoucherGLJournals] CHECK CONSTRAINT [EPaymentVoucher_PaymentVoucherGLJournals]
GO
ALTER TABLE [dbo].[PaymentVoucherGLJournals]  WITH CHECK ADD  CONSTRAINT [EPaymentVoucherGLJournal_GLJournal] FOREIGN KEY([GLJournalId])
REFERENCES [dbo].[GLJournals] ([Id])
GO
ALTER TABLE [dbo].[PaymentVoucherGLJournals] CHECK CONSTRAINT [EPaymentVoucherGLJournal_GLJournal]
GO
