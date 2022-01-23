SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DocumentPermissions](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Permission] [nvarchar](1) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[UserId] [bigint] NOT NULL,
	[DocumentTypePermissionId] [bigint] NULL,
	[DocumentInstanceId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[DocumentPermissions]  WITH CHECK ADD  CONSTRAINT [EDocumentInstance_DocumentPermissions] FOREIGN KEY([DocumentInstanceId])
REFERENCES [dbo].[DocumentInstances] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[DocumentPermissions] CHECK CONSTRAINT [EDocumentInstance_DocumentPermissions]
GO
ALTER TABLE [dbo].[DocumentPermissions]  WITH CHECK ADD  CONSTRAINT [EDocumentPermission_DocumentTypePermission] FOREIGN KEY([DocumentTypePermissionId])
REFERENCES [dbo].[DocumentTypePermissions] ([Id])
GO
ALTER TABLE [dbo].[DocumentPermissions] CHECK CONSTRAINT [EDocumentPermission_DocumentTypePermission]
GO
ALTER TABLE [dbo].[DocumentPermissions]  WITH CHECK ADD  CONSTRAINT [EDocumentPermission_User] FOREIGN KEY([UserId])
REFERENCES [dbo].[Users] ([Id])
GO
ALTER TABLE [dbo].[DocumentPermissions] CHECK CONSTRAINT [EDocumentPermission_User]
GO
