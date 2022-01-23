SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[UDFs](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[VendorID] [bigint] NULL,
	[UDF1Value] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[UDF2Value] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[UDF3Value] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[UDF4Value] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[UDF5Value] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[UDF1Label] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[UDF2Label] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[UDF3Label] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[UDF4Label] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[UDF5Label] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[CreditApplicationNumber] [bigint] NULL,
	[QuoteRequestID] [bigint] NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[AssetId] [bigint] NULL,
	[InvoiceId] [bigint] NULL,
	[ContractId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[CustomerId] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[UDFs]  WITH CHECK ADD  CONSTRAINT [EUDF_Asset] FOREIGN KEY([AssetId])
REFERENCES [dbo].[Assets] ([Id])
GO
ALTER TABLE [dbo].[UDFs] CHECK CONSTRAINT [EUDF_Asset]
GO
ALTER TABLE [dbo].[UDFs]  WITH CHECK ADD  CONSTRAINT [EUDF_Contract] FOREIGN KEY([ContractId])
REFERENCES [dbo].[Contracts] ([Id])
GO
ALTER TABLE [dbo].[UDFs] CHECK CONSTRAINT [EUDF_Contract]
GO
ALTER TABLE [dbo].[UDFs]  WITH CHECK ADD  CONSTRAINT [EUDF_Customer] FOREIGN KEY([CustomerId])
REFERENCES [dbo].[Customers] ([Id])
GO
ALTER TABLE [dbo].[UDFs] CHECK CONSTRAINT [EUDF_Customer]
GO
ALTER TABLE [dbo].[UDFs]  WITH CHECK ADD  CONSTRAINT [EUDF_Invoice] FOREIGN KEY([InvoiceId])
REFERENCES [dbo].[PayableInvoices] ([Id])
GO
ALTER TABLE [dbo].[UDFs] CHECK CONSTRAINT [EUDF_Invoice]
GO
ALTER TABLE [dbo].[UDFs]  WITH CHECK ADD  CONSTRAINT [EUDF_Vendor] FOREIGN KEY([VendorID])
REFERENCES [dbo].[Vendors] ([Id])
GO
ALTER TABLE [dbo].[UDFs] CHECK CONSTRAINT [EUDF_Vendor]
GO
