SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[QuoteRequestCustomers](
	[Id] [bigint] NOT NULL,
	[IsCreateCustomer] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[FirstName] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[LastName] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[IsCorporate] [bit] NOT NULL,
	[IsSoleProprietor] [bit] NOT NULL,
	[EGNNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[EIKNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[Email] [nvarchar](70) COLLATE Latin1_General_CI_AS NOT NULL,
	[PhoneNumber] [nvarchar](15) COLLATE Latin1_General_CI_AS NOT NULL,
	[Comments] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[CompanyName] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[CustomerId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[QuoteRequestCustomers]  WITH CHECK ADD  CONSTRAINT [EQuoteRequest_QuoteRequestCustomer] FOREIGN KEY([Id])
REFERENCES [dbo].[QuoteRequests] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[QuoteRequestCustomers] CHECK CONSTRAINT [EQuoteRequest_QuoteRequestCustomer]
GO
ALTER TABLE [dbo].[QuoteRequestCustomers]  WITH CHECK ADD  CONSTRAINT [EQuoteRequestCustomer_Customer] FOREIGN KEY([CustomerId])
REFERENCES [dbo].[Customers] ([Id])
GO
ALTER TABLE [dbo].[QuoteRequestCustomers] CHECK CONSTRAINT [EQuoteRequestCustomer_Customer]
GO
