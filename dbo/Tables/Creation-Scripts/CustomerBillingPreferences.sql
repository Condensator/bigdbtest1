SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CustomerBillingPreferences](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[InvoicePreference] [nvarchar](18) COLLATE Latin1_General_CI_AS NOT NULL,
	[EffectiveFromDate] [date] NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ReceivableTypeId] [bigint] NOT NULL,
	[CustomerId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CustomerBillingPreferences]  WITH CHECK ADD  CONSTRAINT [ECustomer_CustomerBillingPreferences] FOREIGN KEY([CustomerId])
REFERENCES [dbo].[Customers] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CustomerBillingPreferences] CHECK CONSTRAINT [ECustomer_CustomerBillingPreferences]
GO
ALTER TABLE [dbo].[CustomerBillingPreferences]  WITH CHECK ADD  CONSTRAINT [ECustomerBillingPreference_ReceivableType] FOREIGN KEY([ReceivableTypeId])
REFERENCES [dbo].[ReceivableTypes] ([Id])
GO
ALTER TABLE [dbo].[CustomerBillingPreferences] CHECK CONSTRAINT [ECustomerBillingPreference_ReceivableType]
GO
