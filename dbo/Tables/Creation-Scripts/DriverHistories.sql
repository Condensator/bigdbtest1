SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DriverHistories](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[LicenseNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[LicenseIssueDate] [date] NULL,
	[LicenseExpiryDate] [date] NULL,
	[AssignedDate] [date] NULL,
	[UnassignedDate] [date] NULL,
	[ReasonDescription] [nvarchar](20) COLLATE Latin1_General_CI_AS NULL,
	[ActivationDate] [date] NULL,
	[DeactivationDate] [date] NULL,
	[AssetId] [bigint] NULL,
	[CustomerId] [bigint] NULL,
	[RelatedDriverId] [bigint] NULL,
	[ContractId] [bigint] NULL,
	[StateId] [bigint] NULL,
	[DriverId] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RowVersion] [timestamp] NOT NULL,
	[SourceModule] [nvarchar](18) COLLATE Latin1_General_CI_AS NOT NULL,
	[SourceId] [bigint] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[DriverHistories]  WITH CHECK ADD  CONSTRAINT [EDriver_DriverHistories] FOREIGN KEY([DriverId])
REFERENCES [dbo].[Drivers] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[DriverHistories] CHECK CONSTRAINT [EDriver_DriverHistories]
GO
ALTER TABLE [dbo].[DriverHistories]  WITH CHECK ADD  CONSTRAINT [EDriverHistory_Asset] FOREIGN KEY([AssetId])
REFERENCES [dbo].[Assets] ([Id])
GO
ALTER TABLE [dbo].[DriverHistories] CHECK CONSTRAINT [EDriverHistory_Asset]
GO
ALTER TABLE [dbo].[DriverHistories]  WITH CHECK ADD  CONSTRAINT [EDriverHistory_Contract] FOREIGN KEY([ContractId])
REFERENCES [dbo].[Contracts] ([Id])
GO
ALTER TABLE [dbo].[DriverHistories] CHECK CONSTRAINT [EDriverHistory_Contract]
GO
ALTER TABLE [dbo].[DriverHistories]  WITH CHECK ADD  CONSTRAINT [EDriverHistory_Customer] FOREIGN KEY([CustomerId])
REFERENCES [dbo].[Customers] ([Id])
GO
ALTER TABLE [dbo].[DriverHistories] CHECK CONSTRAINT [EDriverHistory_Customer]
GO
ALTER TABLE [dbo].[DriverHistories]  WITH CHECK ADD  CONSTRAINT [EDriverHistory_RelatedDriver] FOREIGN KEY([RelatedDriverId])
REFERENCES [dbo].[Drivers] ([Id])
GO
ALTER TABLE [dbo].[DriverHistories] CHECK CONSTRAINT [EDriverHistory_RelatedDriver]
GO
ALTER TABLE [dbo].[DriverHistories]  WITH CHECK ADD  CONSTRAINT [EDriverHistory_State] FOREIGN KEY([StateId])
REFERENCES [dbo].[States] ([Id])
GO
ALTER TABLE [dbo].[DriverHistories] CHECK CONSTRAINT [EDriverHistory_State]
GO
