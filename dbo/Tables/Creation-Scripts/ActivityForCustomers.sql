SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ActivityForCustomers](
	[PaymentDate] [date] NULL,
	[PaymentMode] [nvarchar](13) COLLATE Latin1_General_CI_AS NULL,
	[IsCustomerContacted] [bit] NOT NULL,
	[ContactReference] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[SourceUsed] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[PaymentAmount_Amount] [decimal](16, 2) NULL,
	[PaymentAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[ReferenceInvoiceNumber] [bigint] NULL,
	[CurrentChapter] [nvarchar](15) COLLATE Latin1_General_CI_AS NULL,
	[Chapter] [nvarchar](15) COLLATE Latin1_General_CI_AS NULL,
	[JudgmentDate] [date] NULL,
	[Fee_Amount] [decimal](16, 2) NULL,
	[Fee_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[TotalAmount_Amount] [decimal](16, 2) NULL,
	[TotalAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[CustomerId] [bigint] NULL,
	[CollectionAgentId] [bigint] NULL,
	[PersonContactedId] [bigint] NULL,
	[NewCustomerId] [bigint] NULL,
	[CurrencyId] [bigint] NULL,
	[CourtFilingId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[PromiseToPayDate] [date] NULL,
	[ContractId] [bigint] NULL,
	[Id] [bigint] NOT NULL,
	[DateContractCopySent] [date] NULL,
	[SentTo] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[BillToId] [bigint] NULL,
	[VendorID] [bigint] NULL,
	[LeaseTerminationOption] [nvarchar](11) COLLATE Latin1_General_CI_AS NULL,
	[PayoffAssetStatus] [nvarchar](21) COLLATE Latin1_General_CI_AS NULL,
	[PaydownReason] [nvarchar](30) COLLATE Latin1_General_CI_AS NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ActivityForCustomers]  WITH CHECK ADD  CONSTRAINT [EActivity_ActivityForCustomer] FOREIGN KEY([Id])
REFERENCES [dbo].[Activities] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[ActivityForCustomers] CHECK CONSTRAINT [EActivity_ActivityForCustomer]
GO
ALTER TABLE [dbo].[ActivityForCustomers]  WITH CHECK ADD  CONSTRAINT [EActivityForCustomer_BillTo] FOREIGN KEY([BillToId])
REFERENCES [dbo].[BillToes] ([Id])
GO
ALTER TABLE [dbo].[ActivityForCustomers] CHECK CONSTRAINT [EActivityForCustomer_BillTo]
GO
ALTER TABLE [dbo].[ActivityForCustomers]  WITH CHECK ADD  CONSTRAINT [EActivityForCustomer_CollectionAgent] FOREIGN KEY([CollectionAgentId])
REFERENCES [dbo].[Vendors] ([Id])
GO
ALTER TABLE [dbo].[ActivityForCustomers] CHECK CONSTRAINT [EActivityForCustomer_CollectionAgent]
GO
ALTER TABLE [dbo].[ActivityForCustomers]  WITH CHECK ADD  CONSTRAINT [EActivityForCustomer_Contract] FOREIGN KEY([ContractId])
REFERENCES [dbo].[Contracts] ([Id])
GO
ALTER TABLE [dbo].[ActivityForCustomers] CHECK CONSTRAINT [EActivityForCustomer_Contract]
GO
ALTER TABLE [dbo].[ActivityForCustomers]  WITH CHECK ADD  CONSTRAINT [EActivityForCustomer_CourtFiling] FOREIGN KEY([CourtFilingId])
REFERENCES [dbo].[CourtFilings] ([Id])
GO
ALTER TABLE [dbo].[ActivityForCustomers] CHECK CONSTRAINT [EActivityForCustomer_CourtFiling]
GO
ALTER TABLE [dbo].[ActivityForCustomers]  WITH CHECK ADD  CONSTRAINT [EActivityForCustomer_Currency] FOREIGN KEY([CurrencyId])
REFERENCES [dbo].[Currencies] ([Id])
GO
ALTER TABLE [dbo].[ActivityForCustomers] CHECK CONSTRAINT [EActivityForCustomer_Currency]
GO
ALTER TABLE [dbo].[ActivityForCustomers]  WITH CHECK ADD  CONSTRAINT [EActivityForCustomer_Customer] FOREIGN KEY([CustomerId])
REFERENCES [dbo].[Customers] ([Id])
GO
ALTER TABLE [dbo].[ActivityForCustomers] CHECK CONSTRAINT [EActivityForCustomer_Customer]
GO
ALTER TABLE [dbo].[ActivityForCustomers]  WITH CHECK ADD  CONSTRAINT [EActivityForCustomer_NewCustomer] FOREIGN KEY([NewCustomerId])
REFERENCES [dbo].[Customers] ([Id])
GO
ALTER TABLE [dbo].[ActivityForCustomers] CHECK CONSTRAINT [EActivityForCustomer_NewCustomer]
GO
ALTER TABLE [dbo].[ActivityForCustomers]  WITH CHECK ADD  CONSTRAINT [EActivityForCustomer_PersonContacted] FOREIGN KEY([PersonContactedId])
REFERENCES [dbo].[PartyContacts] ([Id])
GO
ALTER TABLE [dbo].[ActivityForCustomers] CHECK CONSTRAINT [EActivityForCustomer_PersonContacted]
GO
ALTER TABLE [dbo].[ActivityForCustomers]  WITH CHECK ADD  CONSTRAINT [EActivityForCustomer_Vendor] FOREIGN KEY([VendorID])
REFERENCES [dbo].[Vendors] ([Id])
GO
ALTER TABLE [dbo].[ActivityForCustomers] CHECK CONSTRAINT [EActivityForCustomer_Vendor]
GO
