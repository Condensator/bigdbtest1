SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[UserPasswordHistories](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Password] [nvarchar](65) COLLATE Latin1_General_CI_AS NOT NULL,
	[PasswordChangeReason] [nvarchar](11) COLLATE Latin1_General_CI_AS NOT NULL,
	[ChangedDate] [date] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[UserId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[UserPasswordHistories]  WITH CHECK ADD  CONSTRAINT [EUserPasswordHistory_User] FOREIGN KEY([UserId])
REFERENCES [dbo].[Users] ([Id])
GO
ALTER TABLE [dbo].[UserPasswordHistories] CHECK CONSTRAINT [EUserPasswordHistory_User]
GO
