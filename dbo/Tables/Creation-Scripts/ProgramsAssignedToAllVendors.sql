SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ProgramsAssignedToAllVendors](
	[IsAssigned] [bit] NOT NULL,
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[AssignmentDate] [date] NOT NULL,
	[UnassignmentDate] [date] NULL,
	[ExternalVendorCode] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[LineofBusinessId] [bigint] NULL,
	[ProgramVendorId] [bigint] NULL,
	[ProgramId] [bigint] NOT NULL,
	[VendorId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[IsDefault] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ProgramsAssignedToAllVendors]  WITH CHECK ADD  CONSTRAINT [EProgramsAssignedToAllVendor_LineofBusiness] FOREIGN KEY([LineofBusinessId])
REFERENCES [dbo].[LineofBusinesses] ([Id])
GO
ALTER TABLE [dbo].[ProgramsAssignedToAllVendors] CHECK CONSTRAINT [EProgramsAssignedToAllVendor_LineofBusiness]
GO
ALTER TABLE [dbo].[ProgramsAssignedToAllVendors]  WITH CHECK ADD  CONSTRAINT [EProgramsAssignedToAllVendor_Program] FOREIGN KEY([ProgramId])
REFERENCES [dbo].[Programs] ([Id])
GO
ALTER TABLE [dbo].[ProgramsAssignedToAllVendors] CHECK CONSTRAINT [EProgramsAssignedToAllVendor_Program]
GO
ALTER TABLE [dbo].[ProgramsAssignedToAllVendors]  WITH CHECK ADD  CONSTRAINT [EProgramsAssignedToAllVendor_ProgramVendor] FOREIGN KEY([ProgramVendorId])
REFERENCES [dbo].[Vendors] ([Id])
GO
ALTER TABLE [dbo].[ProgramsAssignedToAllVendors] CHECK CONSTRAINT [EProgramsAssignedToAllVendor_ProgramVendor]
GO
ALTER TABLE [dbo].[ProgramsAssignedToAllVendors]  WITH CHECK ADD  CONSTRAINT [EVendor_ProgramsAssignedToAllVendors] FOREIGN KEY([VendorId])
REFERENCES [dbo].[Vendors] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[ProgramsAssignedToAllVendors] CHECK CONSTRAINT [EVendor_ProgramsAssignedToAllVendors]
GO
