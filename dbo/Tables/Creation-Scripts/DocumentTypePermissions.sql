SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DocumentTypePermissions](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Permission] [nvarchar](1) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[DocumentTypeId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[AssignmentType] [nvarchar](16) COLLATE Latin1_General_CI_AS NULL,
	[Condition] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[ConditionFor] [nvarchar](16) COLLATE Latin1_General_CI_AS NULL,
	[CreationAllowed] [nvarchar](7) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsOverridable] [bit] NOT NULL,
	[IsReevaluate] [bit] NOT NULL,
	[UserSelectionId] [bigint] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[DocumentTypePermissions]  WITH CHECK ADD  CONSTRAINT [EDocumentType_DocumentTypePermissions] FOREIGN KEY([DocumentTypeId])
REFERENCES [dbo].[DocumentTypes] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[DocumentTypePermissions] CHECK CONSTRAINT [EDocumentType_DocumentTypePermissions]
GO
ALTER TABLE [dbo].[DocumentTypePermissions]  WITH CHECK ADD  CONSTRAINT [EDocumentTypePermission_UserSelection] FOREIGN KEY([UserSelectionId])
REFERENCES [dbo].[UserSelectionParams] ([Id])
GO
ALTER TABLE [dbo].[DocumentTypePermissions] CHECK CONSTRAINT [EDocumentTypePermission_UserSelection]
GO
