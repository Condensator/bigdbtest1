CREATE TYPE [dbo].[UserLoginAudit] AS TABLE(
	[LoginName] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ClientIPAddress] [nvarchar](39) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsLoginSuccessful] [bit] NOT NULL,
	[LogoutTime] [datetimeoffset](7) NULL,
	[IsWindowsAuthenticated] [bit] NOT NULL,
	[Site] [nvarchar](14) COLLATE Latin1_General_CI_AS NOT NULL,
	[UserAgent] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[UserId] [bigint] NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
