SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[VendorPayoffTemplateAssignments](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsDefault] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[PayOffTemplateId] [bigint] NOT NULL,
	[VendorId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[IsAvailableInVendorPortal] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[VendorPayoffTemplateAssignments]  WITH CHECK ADD  CONSTRAINT [EVendor_VendorPayoffTemplateAssignments] FOREIGN KEY([VendorId])
REFERENCES [dbo].[Vendors] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[VendorPayoffTemplateAssignments] CHECK CONSTRAINT [EVendor_VendorPayoffTemplateAssignments]
GO
ALTER TABLE [dbo].[VendorPayoffTemplateAssignments]  WITH CHECK ADD  CONSTRAINT [EVendorPayoffTemplateAssignment_PayOffTemplate] FOREIGN KEY([PayOffTemplateId])
REFERENCES [dbo].[PayOffTemplates] ([Id])
GO
ALTER TABLE [dbo].[VendorPayoffTemplateAssignments] CHECK CONSTRAINT [EVendorPayoffTemplateAssignment_PayOffTemplate]
GO
