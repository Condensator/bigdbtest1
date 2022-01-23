SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DashboardDetails](
	[Id] [bigint] NOT NULL,
	[DisplayText1] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[DisplayText2] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RowVersion] [timestamp] NOT NULL,
	[DisplayText3] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[DashboardDetails]  WITH CHECK ADD  CONSTRAINT [EDashboardProfile_DashboardDetail] FOREIGN KEY([Id])
REFERENCES [dbo].[DashboardProfiles] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[DashboardDetails] CHECK CONSTRAINT [EDashboardProfile_DashboardDetail]
GO
