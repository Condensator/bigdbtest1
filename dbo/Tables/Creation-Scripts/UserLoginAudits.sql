SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[UserLoginAudits](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[LoginName] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[ClientIPAddress] [nvarchar](39) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsLoginSuccessful] [bit] NOT NULL,
	[LogoutTime] [datetimeoffset](7) NULL,
	[IsWindowsAuthenticated] [bit] NOT NULL,
	[Site] [nvarchar](14) COLLATE Latin1_General_CI_AS NOT NULL,
	[UserAgent] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[UserId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[UserLoginAudits]  WITH CHECK ADD  CONSTRAINT [EUserLoginAudit_User] FOREIGN KEY([UserId])
REFERENCES [dbo].[Users] ([Id])
GO
ALTER TABLE [dbo].[UserLoginAudits] CHECK CONSTRAINT [EUserLoginAudit_User]
GO
