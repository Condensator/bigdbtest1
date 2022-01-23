SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BulkUploadInstances](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[ImportedFile_Source] [nvarchar](250) COLLATE Latin1_General_CI_AS NOT NULL,
	[ImportedFile_Type] [nvarchar](5) COLLATE Latin1_General_CI_AS NOT NULL,
	[ImportedFile_Content] [varbinary](82) NOT NULL,
	[JobInstanceId] [bigint] NULL,
	[ProfileId] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[BulkUploadInstances]  WITH CHECK ADD  CONSTRAINT [EBulkUploadInstance_JobInstance] FOREIGN KEY([JobInstanceId])
REFERENCES [dbo].[JobInstances] ([Id])
GO
ALTER TABLE [dbo].[BulkUploadInstances] CHECK CONSTRAINT [EBulkUploadInstance_JobInstance]
GO
ALTER TABLE [dbo].[BulkUploadInstances]  WITH CHECK ADD  CONSTRAINT [EBulkUploadInstance_Profile] FOREIGN KEY([ProfileId])
REFERENCES [dbo].[BulkUploadProfiles] ([Id])
GO
ALTER TABLE [dbo].[BulkUploadInstances] CHECK CONSTRAINT [EBulkUploadInstance_Profile]
GO
