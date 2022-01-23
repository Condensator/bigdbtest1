SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SyndicationProgressPaymentCreditDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Amount_Amount] [decimal](16, 2) NOT NULL,
	[Amount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[PayableInvoiceAssetId] [bigint] NOT NULL,
	[LeaseSyndicationProgressPaymentCreditId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[SyndicationProgressPaymentCreditDetails]  WITH CHECK ADD  CONSTRAINT [ELeaseSyndicationProgressPaymentCredit_SyndicationProgressPaymentCreditDetails] FOREIGN KEY([LeaseSyndicationProgressPaymentCreditId])
REFERENCES [dbo].[LeaseSyndicationProgressPaymentCredits] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[SyndicationProgressPaymentCreditDetails] CHECK CONSTRAINT [ELeaseSyndicationProgressPaymentCredit_SyndicationProgressPaymentCreditDetails]
GO
ALTER TABLE [dbo].[SyndicationProgressPaymentCreditDetails]  WITH CHECK ADD  CONSTRAINT [ESyndicationProgressPaymentCreditDetail_PayableInvoiceAsset] FOREIGN KEY([PayableInvoiceAssetId])
REFERENCES [dbo].[PayableInvoiceAssets] ([Id])
GO
ALTER TABLE [dbo].[SyndicationProgressPaymentCreditDetails] CHECK CONSTRAINT [ESyndicationProgressPaymentCreditDetail_PayableInvoiceAsset]
GO
