SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CustomerCIPHistories](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[FirstName] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[LastName] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[CompanyName] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[UniqueIdentificationNumber] [nvarchar](18) COLLATE Latin1_General_CI_AS NULL,
	[AddressLine1] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[AddressLine2] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[City] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[PostalCode] [nvarchar](12) COLLATE Latin1_General_CI_AS NULL,
	[CIPDocumentSourceForName] [nvarchar](61) COLLATE Latin1_General_CI_AS NULL,
	[CIPDocumentSourceForAddress] [nvarchar](61) COLLATE Latin1_General_CI_AS NULL,
	[CIPDocumentSourceForTaxIdOrSSN] [nvarchar](61) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[StateId] [bigint] NULL,
	[CustomerId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[CIPDocumentSourceNameId] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CustomerCIPHistories]  WITH CHECK ADD  CONSTRAINT [ECustomer_CustomerCIPHistories] FOREIGN KEY([CustomerId])
REFERENCES [dbo].[Customers] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CustomerCIPHistories] CHECK CONSTRAINT [ECustomer_CustomerCIPHistories]
GO
ALTER TABLE [dbo].[CustomerCIPHistories]  WITH CHECK ADD  CONSTRAINT [ECustomerCIPHistory_CIPDocumentSourceName] FOREIGN KEY([CIPDocumentSourceNameId])
REFERENCES [dbo].[CIPDocumentSourceConfigs] ([Id])
GO
ALTER TABLE [dbo].[CustomerCIPHistories] CHECK CONSTRAINT [ECustomerCIPHistory_CIPDocumentSourceName]
GO
ALTER TABLE [dbo].[CustomerCIPHistories]  WITH CHECK ADD  CONSTRAINT [ECustomerCIPHistory_State] FOREIGN KEY([StateId])
REFERENCES [dbo].[States] ([Id])
GO
ALTER TABLE [dbo].[CustomerCIPHistories] CHECK CONSTRAINT [ECustomerCIPHistory_State]
GO
