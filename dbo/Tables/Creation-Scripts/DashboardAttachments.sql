SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DashboardAttachments](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[DocumentName] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[Title] [nvarchar](20) COLLATE Latin1_General_CI_AS NOT NULL,
	[DocumentDescription] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[Attachment_Source] [nvarchar](250) COLLATE Latin1_General_CI_AS NOT NULL,
	[Attachment_Type] [nvarchar](5) COLLATE Latin1_General_CI_AS NOT NULL,
	[Attachment_Content] [varbinary](82) NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[DashboardProfileId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[IsActive] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[DashboardAttachments]  WITH CHECK ADD  CONSTRAINT [EDashboardProfile_DashboardAttachments] FOREIGN KEY([DashboardProfileId])
REFERENCES [dbo].[DashboardProfiles] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[DashboardAttachments] CHECK CONSTRAINT [EDashboardProfile_DashboardAttachments]
GO
