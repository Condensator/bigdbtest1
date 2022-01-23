SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PayoffSundries](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[SundryType] [nvarchar](14) COLLATE Latin1_General_CI_AS NOT NULL,
	[IncludeInPayoffInvoice] [bit] NOT NULL,
	[Amount_Amount] [decimal](16, 2) NOT NULL,
	[Amount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[Comment] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[IsSystemGenerated] [bit] NOT NULL,
	[SystemGeneratedType] [nvarchar](20) COLLATE Latin1_General_CI_AS NULL,
	[ReferenceNumber] [int] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ReceivableCodeId] [bigint] NULL,
	[PayableCodeId] [bigint] NULL,
	[LocationId] [bigint] NULL,
	[RemitToId] [bigint] NULL,
	[BillToId] [bigint] NULL,
	[SundryId] [bigint] NULL,
	[CustomerId] [bigint] NULL,
	[VendorId] [bigint] NULL,
	[PayoffId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[PayableWithholdingTaxRate] [decimal](5, 2) NULL,
	[VATAmount_Amount] [decimal](16, 2) NOT NULL,
	[VATAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[PayoffSundries]  WITH CHECK ADD  CONSTRAINT [EPayoff_PayoffSundries] FOREIGN KEY([PayoffId])
REFERENCES [dbo].[Payoffs] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[PayoffSundries] CHECK CONSTRAINT [EPayoff_PayoffSundries]
GO
ALTER TABLE [dbo].[PayoffSundries]  WITH CHECK ADD  CONSTRAINT [EPayoffSundry_BillTo] FOREIGN KEY([BillToId])
REFERENCES [dbo].[BillToes] ([Id])
GO
ALTER TABLE [dbo].[PayoffSundries] CHECK CONSTRAINT [EPayoffSundry_BillTo]
GO
ALTER TABLE [dbo].[PayoffSundries]  WITH CHECK ADD  CONSTRAINT [EPayoffSundry_Customer] FOREIGN KEY([CustomerId])
REFERENCES [dbo].[Customers] ([Id])
GO
ALTER TABLE [dbo].[PayoffSundries] CHECK CONSTRAINT [EPayoffSundry_Customer]
GO
ALTER TABLE [dbo].[PayoffSundries]  WITH CHECK ADD  CONSTRAINT [EPayoffSundry_Location] FOREIGN KEY([LocationId])
REFERENCES [dbo].[Locations] ([Id])
GO
ALTER TABLE [dbo].[PayoffSundries] CHECK CONSTRAINT [EPayoffSundry_Location]
GO
ALTER TABLE [dbo].[PayoffSundries]  WITH CHECK ADD  CONSTRAINT [EPayoffSundry_PayableCode] FOREIGN KEY([PayableCodeId])
REFERENCES [dbo].[PayableCodes] ([Id])
GO
ALTER TABLE [dbo].[PayoffSundries] CHECK CONSTRAINT [EPayoffSundry_PayableCode]
GO
ALTER TABLE [dbo].[PayoffSundries]  WITH CHECK ADD  CONSTRAINT [EPayoffSundry_ReceivableCode] FOREIGN KEY([ReceivableCodeId])
REFERENCES [dbo].[ReceivableCodes] ([Id])
GO
ALTER TABLE [dbo].[PayoffSundries] CHECK CONSTRAINT [EPayoffSundry_ReceivableCode]
GO
ALTER TABLE [dbo].[PayoffSundries]  WITH CHECK ADD  CONSTRAINT [EPayoffSundry_RemitTo] FOREIGN KEY([RemitToId])
REFERENCES [dbo].[RemitToes] ([Id])
GO
ALTER TABLE [dbo].[PayoffSundries] CHECK CONSTRAINT [EPayoffSundry_RemitTo]
GO
ALTER TABLE [dbo].[PayoffSundries]  WITH CHECK ADD  CONSTRAINT [EPayoffSundry_Sundry] FOREIGN KEY([SundryId])
REFERENCES [dbo].[Sundries] ([Id])
GO
ALTER TABLE [dbo].[PayoffSundries] CHECK CONSTRAINT [EPayoffSundry_Sundry]
GO
ALTER TABLE [dbo].[PayoffSundries]  WITH CHECK ADD  CONSTRAINT [EPayoffSundry_Vendor] FOREIGN KEY([VendorId])
REFERENCES [dbo].[Vendors] ([Id])
GO
ALTER TABLE [dbo].[PayoffSundries] CHECK CONSTRAINT [EPayoffSundry_Vendor]
GO
