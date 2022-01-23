SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LeaseSyndicationProgressPaymentCredits](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[TakeDownAmount_Amount] [decimal](16, 2) NOT NULL,
	[TakeDownAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[IsNewlyAdded] [bit] NOT NULL,
	[OtherCostCapitalizedAmount_Amount] [decimal](16, 2) NULL,
	[OtherCostCapitalizedAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[PayableInvoiceOtherCostId] [bigint] NOT NULL,
	[LeaseSyndicationId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[LeaseSyndicationProgressPaymentCredits]  WITH CHECK ADD  CONSTRAINT [ELeaseSyndication_LeaseSyndicationProgressPaymentCredits] FOREIGN KEY([LeaseSyndicationId])
REFERENCES [dbo].[LeaseSyndications] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[LeaseSyndicationProgressPaymentCredits] CHECK CONSTRAINT [ELeaseSyndication_LeaseSyndicationProgressPaymentCredits]
GO
ALTER TABLE [dbo].[LeaseSyndicationProgressPaymentCredits]  WITH CHECK ADD  CONSTRAINT [ELeaseSyndicationProgressPaymentCredit_PayableInvoiceOtherCost] FOREIGN KEY([PayableInvoiceOtherCostId])
REFERENCES [dbo].[PayableInvoiceOtherCosts] ([Id])
GO
ALTER TABLE [dbo].[LeaseSyndicationProgressPaymentCredits] CHECK CONSTRAINT [ELeaseSyndicationProgressPaymentCredit_PayableInvoiceOtherCost]
GO
