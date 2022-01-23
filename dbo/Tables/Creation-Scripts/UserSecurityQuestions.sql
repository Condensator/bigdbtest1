SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[UserSecurityQuestions](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Answer_CT] [varbinary](96) NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[IsActive] [bit] NOT NULL,
	[SecurityQuestionId] [bigint] NULL,
	[UserId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[UserSecurityQuestions]  WITH CHECK ADD  CONSTRAINT [EUser_UserSecurityQuestions] FOREIGN KEY([UserId])
REFERENCES [dbo].[Users] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[UserSecurityQuestions] CHECK CONSTRAINT [EUser_UserSecurityQuestions]
GO
ALTER TABLE [dbo].[UserSecurityQuestions]  WITH CHECK ADD  CONSTRAINT [EUserSecurityQuestion_SecurityQuestion] FOREIGN KEY([SecurityQuestionId])
REFERENCES [dbo].[SecurityQuestionConfigs] ([Id])
GO
ALTER TABLE [dbo].[UserSecurityQuestions] CHECK CONSTRAINT [EUserSecurityQuestion_SecurityQuestion]
GO
