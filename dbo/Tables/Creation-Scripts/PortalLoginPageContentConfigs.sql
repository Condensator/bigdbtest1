SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PortalLoginPageContentConfigs](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Description] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ContactMessage_HTMLContent] [nvarchar](max) COLLATE Latin1_General_CI_AS NOT NULL,
	[EmailContact] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[SubSystemConfigId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[PortalLoginPageContentConfigs]  WITH CHECK ADD  CONSTRAINT [EPortalLoginPageContentConfig_SubSystemConfig] FOREIGN KEY([SubSystemConfigId])
REFERENCES [dbo].[SubSystemConfigs] ([Id])
GO
ALTER TABLE [dbo].[PortalLoginPageContentConfigs] CHECK CONSTRAINT [EPortalLoginPageContentConfig_SubSystemConfig]
GO
