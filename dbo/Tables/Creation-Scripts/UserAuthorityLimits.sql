SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[UserAuthorityLimits](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Description] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[Limit_Amount] [decimal](24, 2) NOT NULL,
	[Limit_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[AuthorityId] [bigint] NOT NULL,
	[UserId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[Factor] [decimal](8, 4) NULL,
	[PaymentCount] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[UserAuthorityLimits]  WITH CHECK ADD  CONSTRAINT [EUser_UserAuthorityLimits] FOREIGN KEY([UserId])
REFERENCES [dbo].[Users] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[UserAuthorityLimits] CHECK CONSTRAINT [EUser_UserAuthorityLimits]
GO
ALTER TABLE [dbo].[UserAuthorityLimits]  WITH CHECK ADD  CONSTRAINT [EUserAuthorityLimit_Authority] FOREIGN KEY([AuthorityId])
REFERENCES [dbo].[Authorities] ([Id])
GO
ALTER TABLE [dbo].[UserAuthorityLimits] CHECK CONSTRAINT [EUserAuthorityLimit_Authority]
GO
