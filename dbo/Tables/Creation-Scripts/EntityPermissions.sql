SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[EntityPermissions](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](250) COLLATE Latin1_General_CI_AS NOT NULL,
	[Access] [nvarchar](1) COLLATE Latin1_General_CI_AS NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[PermissionHeaderId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[EntityPermissions]  WITH CHECK ADD  CONSTRAINT [EPermissionHeader_EntityPermissions] FOREIGN KEY([PermissionHeaderId])
REFERENCES [dbo].[PermissionHeaders] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[EntityPermissions] CHECK CONSTRAINT [EPermissionHeader_EntityPermissions]
GO
