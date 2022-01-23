SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ChildShellCustomers](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ShellCustomerDetailId] [bigint] NOT NULL,
	[CustomerId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ChildShellCustomers]  WITH CHECK ADD  CONSTRAINT [EChildShellCustomer_Customer] FOREIGN KEY([CustomerId])
REFERENCES [dbo].[Customers] ([Id])
GO
ALTER TABLE [dbo].[ChildShellCustomers] CHECK CONSTRAINT [EChildShellCustomer_Customer]
GO
ALTER TABLE [dbo].[ChildShellCustomers]  WITH CHECK ADD  CONSTRAINT [EChildShellCustomer_ShellCustomerDetail] FOREIGN KEY([ShellCustomerDetailId])
REFERENCES [dbo].[ShellCustomerDetails] ([Id])
GO
ALTER TABLE [dbo].[ChildShellCustomers] CHECK CONSTRAINT [EChildShellCustomer_ShellCustomerDetail]
GO
