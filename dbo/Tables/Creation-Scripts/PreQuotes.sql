SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PreQuotes](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[QuoteNumber] [bigint] NOT NULL,
	[Status] [nvarchar](23) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsFutureQuote] [bit] NOT NULL,
	[QuoteType] [nvarchar](14) COLLATE Latin1_General_CI_AS NOT NULL,
	[EffectiveDate] [date] NOT NULL,
	[GoodThroughDate] [date] NULL,
	[PaydownReason] [nvarchar](30) COLLATE Latin1_General_CI_AS NULL,
	[PayoffAssetStatus] [nvarchar](21) COLLATE Latin1_General_CI_AS NULL,
	[IsMultiQuote] [bit] NOT NULL,
	[IsRenewalQuote] [bit] NOT NULL,
	[Comment] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[CustomerId] [bigint] NOT NULL,
	[TerminationOptionId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[CurrencyId] [bigint] NULL,
	[DueDate] [date] NULL,
	[BillingComment] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[BillToId] [bigint] NULL,
	[RemitToId] [bigint] NULL,
	[LegalEntityId] [bigint] NULL,
	[BusinessUnitId] [bigint] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[PreQuotes]  WITH CHECK ADD  CONSTRAINT [EPreQuote_BillTo] FOREIGN KEY([BillToId])
REFERENCES [dbo].[BillToes] ([Id])
GO
ALTER TABLE [dbo].[PreQuotes] CHECK CONSTRAINT [EPreQuote_BillTo]
GO
ALTER TABLE [dbo].[PreQuotes]  WITH CHECK ADD  CONSTRAINT [EPreQuote_BusinessUnit] FOREIGN KEY([BusinessUnitId])
REFERENCES [dbo].[BusinessUnits] ([Id])
GO
ALTER TABLE [dbo].[PreQuotes] CHECK CONSTRAINT [EPreQuote_BusinessUnit]
GO
ALTER TABLE [dbo].[PreQuotes]  WITH CHECK ADD  CONSTRAINT [EPreQuote_Currency] FOREIGN KEY([CurrencyId])
REFERENCES [dbo].[Currencies] ([Id])
GO
ALTER TABLE [dbo].[PreQuotes] CHECK CONSTRAINT [EPreQuote_Currency]
GO
ALTER TABLE [dbo].[PreQuotes]  WITH CHECK ADD  CONSTRAINT [EPreQuote_Customer] FOREIGN KEY([CustomerId])
REFERENCES [dbo].[Customers] ([Id])
GO
ALTER TABLE [dbo].[PreQuotes] CHECK CONSTRAINT [EPreQuote_Customer]
GO
ALTER TABLE [dbo].[PreQuotes]  WITH CHECK ADD  CONSTRAINT [EPreQuote_LegalEntity] FOREIGN KEY([LegalEntityId])
REFERENCES [dbo].[LegalEntities] ([Id])
GO
ALTER TABLE [dbo].[PreQuotes] CHECK CONSTRAINT [EPreQuote_LegalEntity]
GO
ALTER TABLE [dbo].[PreQuotes]  WITH CHECK ADD  CONSTRAINT [EPreQuote_RemitTo] FOREIGN KEY([RemitToId])
REFERENCES [dbo].[RemitToes] ([Id])
GO
ALTER TABLE [dbo].[PreQuotes] CHECK CONSTRAINT [EPreQuote_RemitTo]
GO
ALTER TABLE [dbo].[PreQuotes]  WITH CHECK ADD  CONSTRAINT [EPreQuote_TerminationOption] FOREIGN KEY([TerminationOptionId])
REFERENCES [dbo].[PayoffTerminationOptions] ([Id])
GO
ALTER TABLE [dbo].[PreQuotes] CHECK CONSTRAINT [EPreQuote_TerminationOption]
GO
