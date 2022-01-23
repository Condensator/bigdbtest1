SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PlateAssignmentHistories](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IssuedDate] [date] NULL,
	[AssignedDate] [date] NOT NULL,
	[UnassignedDate] [date] NULL,
	[LastModifiedDate] [datetimeoffset](7) NOT NULL,
	[PlateHistoryReason] [nvarchar](15) COLLATE Latin1_General_CI_AS NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[AssetId] [bigint] NULL,
	[CustomerId] [bigint] NULL,
	[ContractId] [bigint] NULL,
	[PlateId] [bigint] NOT NULL,
	[UserId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[PlateTypeId] [bigint] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[PlateAssignmentHistories]  WITH CHECK ADD  CONSTRAINT [EPlate_PlateAssignmentHistories] FOREIGN KEY([PlateId])
REFERENCES [dbo].[Plates] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[PlateAssignmentHistories] CHECK CONSTRAINT [EPlate_PlateAssignmentHistories]
GO
ALTER TABLE [dbo].[PlateAssignmentHistories]  WITH CHECK ADD  CONSTRAINT [EPlateAssignmentHistory_Asset] FOREIGN KEY([AssetId])
REFERENCES [dbo].[Assets] ([Id])
GO
ALTER TABLE [dbo].[PlateAssignmentHistories] CHECK CONSTRAINT [EPlateAssignmentHistory_Asset]
GO
ALTER TABLE [dbo].[PlateAssignmentHistories]  WITH CHECK ADD  CONSTRAINT [EPlateAssignmentHistory_Contract] FOREIGN KEY([ContractId])
REFERENCES [dbo].[Contracts] ([Id])
GO
ALTER TABLE [dbo].[PlateAssignmentHistories] CHECK CONSTRAINT [EPlateAssignmentHistory_Contract]
GO
ALTER TABLE [dbo].[PlateAssignmentHistories]  WITH CHECK ADD  CONSTRAINT [EPlateAssignmentHistory_Customer] FOREIGN KEY([CustomerId])
REFERENCES [dbo].[Customers] ([Id])
GO
ALTER TABLE [dbo].[PlateAssignmentHistories] CHECK CONSTRAINT [EPlateAssignmentHistory_Customer]
GO
ALTER TABLE [dbo].[PlateAssignmentHistories]  WITH CHECK ADD  CONSTRAINT [EPlateAssignmentHistory_PlateType] FOREIGN KEY([PlateTypeId])
REFERENCES [dbo].[PlateTypes] ([Id])
GO
ALTER TABLE [dbo].[PlateAssignmentHistories] CHECK CONSTRAINT [EPlateAssignmentHistory_PlateType]
GO
ALTER TABLE [dbo].[PlateAssignmentHistories]  WITH CHECK ADD  CONSTRAINT [EPlateAssignmentHistory_User] FOREIGN KEY([UserId])
REFERENCES [dbo].[Users] ([Id])
GO
ALTER TABLE [dbo].[PlateAssignmentHistories] CHECK CONSTRAINT [EPlateAssignmentHistory_User]
GO
