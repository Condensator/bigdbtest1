CREATE TYPE [dbo].[ExtLoginRequestFailureLog] AS TABLE(
	[Request] [nvarchar](500) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[LoginRequest] [bit] NOT NULL,
	[HeaderKey] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[UserName] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[PortalName] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[LoginStatus] [nvarchar](7) COLLATE Latin1_General_CI_AS NOT NULL,
	[ErrorMessage] [nvarchar](1000) COLLATE Latin1_General_CI_AS NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
