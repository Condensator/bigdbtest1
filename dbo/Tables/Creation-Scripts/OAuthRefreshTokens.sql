SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[OAuthRefreshTokens](
	[RefreshTokenKey] [nvarchar](36) COLLATE Latin1_General_CI_AS MASKED WITH (FUNCTION = 'default()') NOT NULL,
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[IssuedUtc] [datetimeoffset](7) NOT NULL,
	[ExpiresUtc] [datetimeoffset](7) NOT NULL,
	[ProtectedTicket] [nvarchar](max) COLLATE Latin1_General_CI_AS MASKED WITH (FUNCTION = 'default()') NOT NULL,
	[IsActive] [bit] NOT NULL,
	[OAuthClientId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[OAuthRefreshTokens]  WITH CHECK ADD  CONSTRAINT [EOAuthRefreshToken_OAuthClient] FOREIGN KEY([OAuthClientId])
REFERENCES [dbo].[OAuthClients] ([Id])
GO
ALTER TABLE [dbo].[OAuthRefreshTokens] CHECK CONSTRAINT [EOAuthRefreshToken_OAuthClient]
GO
