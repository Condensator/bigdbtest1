SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CustomerConfigDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[PaidOffViewDays] [int] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[DashboardProfileId] [bigint] NULL,
	[CustomerConfigId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[IsDisplaySoftAsset] [bit] NOT NULL,
	[PartyId] [bigint] NOT NULL,
	[CustomDashboardApplicable] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CustomerConfigDetails]  WITH CHECK ADD  CONSTRAINT [ECustomerConfig_CustomerConfigDetails] FOREIGN KEY([CustomerConfigId])
REFERENCES [dbo].[CustomerConfigs] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CustomerConfigDetails] CHECK CONSTRAINT [ECustomerConfig_CustomerConfigDetails]
GO
ALTER TABLE [dbo].[CustomerConfigDetails]  WITH CHECK ADD  CONSTRAINT [ECustomerConfigDetail_DashboardProfile] FOREIGN KEY([DashboardProfileId])
REFERENCES [dbo].[DashboardProfiles] ([Id])
GO
ALTER TABLE [dbo].[CustomerConfigDetails] CHECK CONSTRAINT [ECustomerConfigDetail_DashboardProfile]
GO
ALTER TABLE [dbo].[CustomerConfigDetails]  WITH CHECK ADD  CONSTRAINT [ECustomerConfigDetail_Party] FOREIGN KEY([PartyId])
REFERENCES [dbo].[Parties] ([Id])
GO
ALTER TABLE [dbo].[CustomerConfigDetails] CHECK CONSTRAINT [ECustomerConfigDetail_Party]
GO
