SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Users](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[FirstName] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[LastName] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[FullName] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[LoginName] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsWindowsAuthenticated] [bit] NOT NULL,
	[Password] [nvarchar](65) COLLATE Latin1_General_CI_AS NULL,
	[PhoneNumber] [nvarchar](15) COLLATE Latin1_General_CI_AS NULL,
	[FaxNumber] [nvarchar](15) COLLATE Latin1_General_CI_AS NULL,
	[PhoneExtensionNumber] [nvarchar](5) COLLATE Latin1_General_CI_AS NULL,
	[Email] [nvarchar](70) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsEmailNotificationAllowed] [bit] NOT NULL,
	[LoginEffectiveDate] [date] NULL,
	[LoginExpiryDate] [date] NULL,
	[IsLoginBlocked] [bit] NOT NULL,
	[IsAdminBlocked] [bit] NOT NULL,
	[LoginBlockedTime] [datetimeoffset](7) NULL,
	[ForcePasswordReset] [bit] NOT NULL,
	[CreationDate] [date] NOT NULL,
	[ActivationDate] [date] NULL,
	[DeactivationDate] [date] NULL,
	[CanLogin] [bit] NOT NULL,
	[LoginFailureCounter] [int] NOT NULL,
	[ApprovalStatus] [nvarchar](8) COLLATE Latin1_General_CI_AS NOT NULL,
	[Title] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[DiligenzAccountID] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[DiligenzContactNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[IsFullAccess] [bit] NOT NULL,
	[DefaultBusinessUnitId] [bigint] NULL,
	[AdminUserId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[IsFactorAuthenticationEnabled] [bit] NOT NULL,
	[IsFactorAuthorizationEnabled] [bit] NOT NULL,
	[MultiFactorAuthenticationId] [bigint] NULL,
	[ContractId] [bigint] NULL,
	[BillToId] [bigint] NULL,
	[ExternalUserId] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[DomainId] [bigint] NULL,
	[ESignJWTUserId] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[ProfilePicture_Source] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[ProfilePicture_Type] [nvarchar](5) COLLATE Latin1_General_CI_AS NULL,
	[ProfilePicture_Content] [varbinary](82) NULL,
	[OrganizationConfigId] [bigint] NULL,
	[EGN_CT] [varbinary](64) NULL,
	[MiddleName] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[IdCardNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[IssuedBy] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[IssuedIn] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[PermanentAddressCity] [nvarchar](2000) COLLATE Latin1_General_CI_AS NULL,
	[Role] [nvarchar](14) COLLATE Latin1_General_CI_AS NULL,
	[IsAttorney] [bit] NOT NULL,
	[PowerOfAttorneyNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[Validity] [date] NULL,
	[Notary] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[NotaryRegistrationNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[SignatureNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[Users]  WITH CHECK ADD  CONSTRAINT [EUser_AdminUser] FOREIGN KEY([AdminUserId])
REFERENCES [dbo].[Users] ([Id])
GO
ALTER TABLE [dbo].[Users] CHECK CONSTRAINT [EUser_AdminUser]
GO
ALTER TABLE [dbo].[Users]  WITH CHECK ADD  CONSTRAINT [EUser_BillTo] FOREIGN KEY([BillToId])
REFERENCES [dbo].[BillToes] ([Id])
GO
ALTER TABLE [dbo].[Users] CHECK CONSTRAINT [EUser_BillTo]
GO
ALTER TABLE [dbo].[Users]  WITH CHECK ADD  CONSTRAINT [EUser_Contract] FOREIGN KEY([ContractId])
REFERENCES [dbo].[Contracts] ([Id])
GO
ALTER TABLE [dbo].[Users] CHECK CONSTRAINT [EUser_Contract]
GO
ALTER TABLE [dbo].[Users]  WITH CHECK ADD  CONSTRAINT [EUser_DefaultBusinessUnit] FOREIGN KEY([DefaultBusinessUnitId])
REFERENCES [dbo].[BusinessUnits] ([Id])
GO
ALTER TABLE [dbo].[Users] CHECK CONSTRAINT [EUser_DefaultBusinessUnit]
GO
ALTER TABLE [dbo].[Users]  WITH CHECK ADD  CONSTRAINT [EUser_Domain] FOREIGN KEY([DomainId])
REFERENCES [dbo].[DomainServerConfigs] ([Id])
GO
ALTER TABLE [dbo].[Users] CHECK CONSTRAINT [EUser_Domain]
GO
ALTER TABLE [dbo].[Users]  WITH CHECK ADD  CONSTRAINT [EUser_MultiFactorAuthentication] FOREIGN KEY([MultiFactorAuthenticationId])
REFERENCES [dbo].[UserFactorAuthentications] ([Id])
GO
ALTER TABLE [dbo].[Users] CHECK CONSTRAINT [EUser_MultiFactorAuthentication]
GO
ALTER TABLE [dbo].[Users]  WITH CHECK ADD  CONSTRAINT [EUser_OrganizationConfig] FOREIGN KEY([OrganizationConfigId])
REFERENCES [dbo].[OrganizationConfigs] ([Id])
GO
ALTER TABLE [dbo].[Users] CHECK CONSTRAINT [EUser_OrganizationConfig]
GO
