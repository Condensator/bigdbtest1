SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PreQuoteLoanDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[PaydownReason] [nvarchar](30) COLLATE Latin1_General_CI_AS NULL,
	[PrincipalPaydown_Amount] [decimal](16, 2) NOT NULL,
	[PrincipalPaydown_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[InterestPaydown_Amount] [decimal](16, 2) NOT NULL,
	[InterestPaydown_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[PrePaymentPenalty_Amount] [decimal](16, 2) NOT NULL,
	[PrePaymentPenalty_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[LateFee_Amount] [decimal](16, 2) NOT NULL,
	[LateFee_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[OtherCharge_Amount] [decimal](16, 2) NOT NULL,
	[OtherCharge_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[PreQuoteLoanId] [bigint] NOT NULL,
	[PreQuoteId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[IsComputationPerformed] [bit] NOT NULL,
	[IsSalesTaxAssessed] [bit] NOT NULL,
	[InterestPaydownSalesTax_Amount] [decimal](16, 2) NOT NULL,
	[InterestPaydownSalesTax_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[PreQuoteLoanDetails]  WITH CHECK ADD  CONSTRAINT [EPreQuote_PreQuoteLoanDetails] FOREIGN KEY([PreQuoteId])
REFERENCES [dbo].[PreQuotes] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[PreQuoteLoanDetails] CHECK CONSTRAINT [EPreQuote_PreQuoteLoanDetails]
GO
ALTER TABLE [dbo].[PreQuoteLoanDetails]  WITH CHECK ADD  CONSTRAINT [EPreQuoteLoanDetail_PreQuoteLoan] FOREIGN KEY([PreQuoteLoanId])
REFERENCES [dbo].[PreQuoteLoans] ([Id])
GO
ALTER TABLE [dbo].[PreQuoteLoanDetails] CHECK CONSTRAINT [EPreQuoteLoanDetail_PreQuoteLoan]
GO
