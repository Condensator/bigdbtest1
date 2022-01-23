CREATE TYPE [dbo].[OAuthClient] AS TABLE(
	[ClientId] [nvarchar](36) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[Secret] [nvarchar](250) COLLATE Latin1_General_CI_AS NOT NULL,
	[Name] [nvarchar](250) COLLATE Latin1_General_CI_AS NOT NULL,
	[RefreshTokenLifeTime] [int] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
