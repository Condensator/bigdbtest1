SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PreQuoteContracts](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[QuoteEffectiveDate] [date] NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ContractId] [bigint] NOT NULL,
	[PreQuoteId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[PreQuoteContracts]  WITH CHECK ADD  CONSTRAINT [EPreQuote_PreQuoteContracts] FOREIGN KEY([PreQuoteId])
REFERENCES [dbo].[PreQuotes] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[PreQuoteContracts] CHECK CONSTRAINT [EPreQuote_PreQuoteContracts]
GO
ALTER TABLE [dbo].[PreQuoteContracts]  WITH CHECK ADD  CONSTRAINT [EPreQuoteContract_Contract] FOREIGN KEY([ContractId])
REFERENCES [dbo].[Contracts] ([Id])
GO
ALTER TABLE [dbo].[PreQuoteContracts] CHECK CONSTRAINT [EPreQuoteContract_Contract]
GO
