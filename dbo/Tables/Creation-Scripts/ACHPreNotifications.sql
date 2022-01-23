SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ACHPreNotifications](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Amount_Amount] [decimal](16, 2) NULL,
	[Amount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[SettlementDate] [date] NULL,
	[CustomerId] [bigint] NULL,
	[BillToId] [bigint] NULL,
	[ContractId] [bigint] NULL,
	[BankAccountId] [bigint] NULL,
	[LegalEntityId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ACHPreNotifications]  WITH CHECK ADD  CONSTRAINT [EACHPreNotification_BankAccount] FOREIGN KEY([BankAccountId])
REFERENCES [dbo].[BankAccounts] ([Id])
GO
ALTER TABLE [dbo].[ACHPreNotifications] CHECK CONSTRAINT [EACHPreNotification_BankAccount]
GO
ALTER TABLE [dbo].[ACHPreNotifications]  WITH CHECK ADD  CONSTRAINT [EACHPreNotification_BillTo] FOREIGN KEY([BillToId])
REFERENCES [dbo].[BillToes] ([Id])
GO
ALTER TABLE [dbo].[ACHPreNotifications] CHECK CONSTRAINT [EACHPreNotification_BillTo]
GO
ALTER TABLE [dbo].[ACHPreNotifications]  WITH CHECK ADD  CONSTRAINT [EACHPreNotification_Contract] FOREIGN KEY([ContractId])
REFERENCES [dbo].[Contracts] ([Id])
GO
ALTER TABLE [dbo].[ACHPreNotifications] CHECK CONSTRAINT [EACHPreNotification_Contract]
GO
ALTER TABLE [dbo].[ACHPreNotifications]  WITH CHECK ADD  CONSTRAINT [EACHPreNotification_Customer] FOREIGN KEY([CustomerId])
REFERENCES [dbo].[Customers] ([Id])
GO
ALTER TABLE [dbo].[ACHPreNotifications] CHECK CONSTRAINT [EACHPreNotification_Customer]
GO
ALTER TABLE [dbo].[ACHPreNotifications]  WITH CHECK ADD  CONSTRAINT [EACHPreNotification_LegalEntity] FOREIGN KEY([LegalEntityId])
REFERENCES [dbo].[LegalEntities] ([Id])
GO
ALTER TABLE [dbo].[ACHPreNotifications] CHECK CONSTRAINT [EACHPreNotification_LegalEntity]
GO
