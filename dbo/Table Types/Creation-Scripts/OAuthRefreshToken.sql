CREATE TYPE [dbo].[OAuthRefreshToken] AS TABLE(
	[RefreshTokenKey] [nvarchar](36) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[IssuedUtc] [datetimeoffset](7) NOT NULL,
	[ExpiresUtc] [datetimeoffset](7) NOT NULL,
	[ProtectedTicket] [nvarchar](max) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[OAuthClientId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
