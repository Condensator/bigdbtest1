SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CreditApplications](
	[Id] [bigint] NOT NULL,
	[CreditApplicationSourceType] [nvarchar](8) COLLATE Latin1_General_CI_AS NOT NULL,
	[Comments] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[Status] [nvarchar](19) COLLATE Latin1_General_CI_AS NULL,
	[IsSalesTaxExempt] [bit] NOT NULL,
	[IsHostedsolution] [bit] NOT NULL,
	[EquipmentDescription] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[CostDetails] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[IsFromVendorPortal] [bit] NOT NULL,
	[NoOfWorkItemsRemaining] [int] NULL,
	[AdditionalInformation] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[ExternalApplicationId] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[SubmittedToCreditDate] [date] NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[VendorId] [bigint] NULL,
	[BillingAddressId] [bigint] NULL,
	[TransactionTypeId] [bigint] NOT NULL,
	[VendorContactId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[DealTypeId] [bigint] NOT NULL,
	[IsCreateCustomer] [bit] NOT NULL,
	[VendorUserId] [bigint] NULL,
	[PartyId] [bigint] NULL,
	[EquipmentVendorId] [bigint] NULL,
	[IsPreApproved] [bit] NOT NULL,
	[PreApprovalLOCId] [bigint] NULL,
	[ProgramId] [bigint] NULL,
	[IsPaymentScheduleParameterChanged] [bit] NOT NULL,
	[IsPricingPerformed] [bit] NOT NULL,
	[TaxRegistrationId] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[EffectiveDate] [date] NULL,
	[IsVATAssessedForPayable] [bit] NOT NULL,
	[IsVATAssessedForReceivable] [bit] NOT NULL,
	[DealerEmail] [nvarchar](70) COLLATE Latin1_General_CI_AS NULL,
	[DealerPhoneNumber] [nvarchar](15) COLLATE Latin1_General_CI_AS NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CreditApplications]  WITH CHECK ADD  CONSTRAINT [ECreditApplication_BillingAddress] FOREIGN KEY([BillingAddressId])
REFERENCES [dbo].[PartyAddresses] ([Id])
GO
ALTER TABLE [dbo].[CreditApplications] CHECK CONSTRAINT [ECreditApplication_BillingAddress]
GO
ALTER TABLE [dbo].[CreditApplications]  WITH CHECK ADD  CONSTRAINT [ECreditApplication_DealType] FOREIGN KEY([DealTypeId])
REFERENCES [dbo].[DealTypes] ([Id])
GO
ALTER TABLE [dbo].[CreditApplications] CHECK CONSTRAINT [ECreditApplication_DealType]
GO
ALTER TABLE [dbo].[CreditApplications]  WITH CHECK ADD  CONSTRAINT [ECreditApplication_EquipmentVendor] FOREIGN KEY([EquipmentVendorId])
REFERENCES [dbo].[Vendors] ([Id])
GO
ALTER TABLE [dbo].[CreditApplications] CHECK CONSTRAINT [ECreditApplication_EquipmentVendor]
GO
ALTER TABLE [dbo].[CreditApplications]  WITH CHECK ADD  CONSTRAINT [ECreditApplication_Party] FOREIGN KEY([PartyId])
REFERENCES [dbo].[Parties] ([Id])
GO
ALTER TABLE [dbo].[CreditApplications] CHECK CONSTRAINT [ECreditApplication_Party]
GO
ALTER TABLE [dbo].[CreditApplications]  WITH CHECK ADD  CONSTRAINT [ECreditApplication_PreApprovalLOC] FOREIGN KEY([PreApprovalLOCId])
REFERENCES [dbo].[CreditProfiles] ([Id])
GO
ALTER TABLE [dbo].[CreditApplications] CHECK CONSTRAINT [ECreditApplication_PreApprovalLOC]
GO
ALTER TABLE [dbo].[CreditApplications]  WITH CHECK ADD  CONSTRAINT [ECreditApplication_Program] FOREIGN KEY([ProgramId])
REFERENCES [dbo].[Programs] ([Id])
GO
ALTER TABLE [dbo].[CreditApplications] CHECK CONSTRAINT [ECreditApplication_Program]
GO
ALTER TABLE [dbo].[CreditApplications]  WITH CHECK ADD  CONSTRAINT [ECreditApplication_TransactionType] FOREIGN KEY([TransactionTypeId])
REFERENCES [dbo].[DealProductTypes] ([Id])
GO
ALTER TABLE [dbo].[CreditApplications] CHECK CONSTRAINT [ECreditApplication_TransactionType]
GO
ALTER TABLE [dbo].[CreditApplications]  WITH CHECK ADD  CONSTRAINT [ECreditApplication_Vendor] FOREIGN KEY([VendorId])
REFERENCES [dbo].[Vendors] ([Id])
GO
ALTER TABLE [dbo].[CreditApplications] CHECK CONSTRAINT [ECreditApplication_Vendor]
GO
ALTER TABLE [dbo].[CreditApplications]  WITH CHECK ADD  CONSTRAINT [ECreditApplication_VendorContact] FOREIGN KEY([VendorContactId])
REFERENCES [dbo].[PartyContacts] ([Id])
GO
ALTER TABLE [dbo].[CreditApplications] CHECK CONSTRAINT [ECreditApplication_VendorContact]
GO
ALTER TABLE [dbo].[CreditApplications]  WITH CHECK ADD  CONSTRAINT [ECreditApplication_VendorUser] FOREIGN KEY([VendorUserId])
REFERENCES [dbo].[Users] ([Id])
GO
ALTER TABLE [dbo].[CreditApplications] CHECK CONSTRAINT [ECreditApplication_VendorUser]
GO
ALTER TABLE [dbo].[CreditApplications]  WITH CHECK ADD  CONSTRAINT [EOpportunity_CreditApplication] FOREIGN KEY([Id])
REFERENCES [dbo].[Opportunities] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CreditApplications] CHECK CONSTRAINT [EOpportunity_CreditApplication]
GO
