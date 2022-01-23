SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CreditApplicationNotifications](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsCreditNotificationAllowed] [bit] NOT NULL,
	[CanNotifyOnApproval] [bit] NOT NULL,
	[CanNotifyOnDecline] [bit] NOT NULL,
	[EntityType] [nvarchar](17) COLLATE Latin1_General_CI_AS NOT NULL,
	[EntityId] [bigint] NOT NULL,
	[IsNewAddress] [bit] NOT NULL,
	[IsNewContact] [bit] NOT NULL,
	[IsVendorDetailRequired] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[ActivationDate] [date] NOT NULL,
	[DeactivationDate] [date] NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[PartyAddressId] [bigint] NULL,
	[PartyContactId] [bigint] NOT NULL,
	[CreditApplicationId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CreditApplicationNotifications]  WITH CHECK ADD  CONSTRAINT [ECreditApplication_CreditApplicationNotifications] FOREIGN KEY([CreditApplicationId])
REFERENCES [dbo].[CreditApplications] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CreditApplicationNotifications] CHECK CONSTRAINT [ECreditApplication_CreditApplicationNotifications]
GO
ALTER TABLE [dbo].[CreditApplicationNotifications]  WITH CHECK ADD  CONSTRAINT [ECreditApplicationNotification_PartyAddress] FOREIGN KEY([PartyAddressId])
REFERENCES [dbo].[PartyAddresses] ([Id])
GO
ALTER TABLE [dbo].[CreditApplicationNotifications] CHECK CONSTRAINT [ECreditApplicationNotification_PartyAddress]
GO
ALTER TABLE [dbo].[CreditApplicationNotifications]  WITH CHECK ADD  CONSTRAINT [ECreditApplicationNotification_PartyContact] FOREIGN KEY([PartyContactId])
REFERENCES [dbo].[PartyContacts] ([Id])
GO
ALTER TABLE [dbo].[CreditApplicationNotifications] CHECK CONSTRAINT [ECreditApplicationNotification_PartyContact]
GO
