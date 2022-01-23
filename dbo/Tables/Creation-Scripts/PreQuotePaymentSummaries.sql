SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PreQuotePaymentSummaries](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[EffectiveDate] [date] NOT NULL,
	[ReceivableCode] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[LastBilledDate] [date] NULL,
	[Current_Amount] [decimal](16, 2) NULL,
	[Current_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[Paid_Amount] [decimal](16, 2) NULL,
	[Paid_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[Delinquent_Amount] [decimal](16, 2) NULL,
	[Delinquent_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[Future_Amount] [decimal](16, 2) NULL,
	[Future_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[Remaining_Amount] [decimal](16, 2) NULL,
	[Remaining_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[Total_Amount] [decimal](16, 2) NULL,
	[Total_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ContractId] [bigint] NULL,
	[PreQuoteId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[PreQuotePaymentSummaries]  WITH CHECK ADD  CONSTRAINT [EPreQuote_PreQuotePaymentSummaries] FOREIGN KEY([PreQuoteId])
REFERENCES [dbo].[PreQuotes] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[PreQuotePaymentSummaries] CHECK CONSTRAINT [EPreQuote_PreQuotePaymentSummaries]
GO
ALTER TABLE [dbo].[PreQuotePaymentSummaries]  WITH CHECK ADD  CONSTRAINT [EPreQuotePaymentSummary_Contract] FOREIGN KEY([ContractId])
REFERENCES [dbo].[Contracts] ([Id])
GO
ALTER TABLE [dbo].[PreQuotePaymentSummaries] CHECK CONSTRAINT [EPreQuotePaymentSummary_Contract]
GO
