SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ReleaseVersionDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[ReleaseScriptName] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsExecuted] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ReleaseVersionId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ReleaseVersionDetails]  WITH CHECK ADD  CONSTRAINT [EReleaseVersion_ReleaseVersionDetails] FOREIGN KEY([ReleaseVersionId])
REFERENCES [dbo].[ReleaseVersions] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[ReleaseVersionDetails] CHECK CONSTRAINT [EReleaseVersion_ReleaseVersionDetails]
GO
