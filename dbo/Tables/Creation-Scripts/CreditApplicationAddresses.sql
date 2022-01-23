SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CreditApplicationAddresses](
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[MainAddressId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[IsSameAsMainAddress] [bit] NOT NULL,
	[BillingAddressId] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CreditApplicationAddresses]  WITH CHECK ADD  CONSTRAINT [ECreditApplication_CreditApplicationAddress] FOREIGN KEY([Id])
REFERENCES [dbo].[CreditApplications] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CreditApplicationAddresses] CHECK CONSTRAINT [ECreditApplication_CreditApplicationAddress]
GO
ALTER TABLE [dbo].[CreditApplicationAddresses]  WITH CHECK ADD  CONSTRAINT [ECreditApplicationAddress_BillingAddress] FOREIGN KEY([BillingAddressId])
REFERENCES [dbo].[PartyAddresses] ([Id])
GO
ALTER TABLE [dbo].[CreditApplicationAddresses] CHECK CONSTRAINT [ECreditApplicationAddress_BillingAddress]
GO
ALTER TABLE [dbo].[CreditApplicationAddresses]  WITH CHECK ADD  CONSTRAINT [ECreditApplicationAddress_MainAddress] FOREIGN KEY([MainAddressId])
REFERENCES [dbo].[PartyAddresses] ([Id])
GO
ALTER TABLE [dbo].[CreditApplicationAddresses] CHECK CONSTRAINT [ECreditApplicationAddress_MainAddress]
GO
