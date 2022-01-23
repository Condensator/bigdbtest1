CREATE TYPE [dbo].[UserPasswordHistory] AS TABLE(
	[Password] [nvarchar](65) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[PasswordChangeReason] [nvarchar](11) COLLATE Latin1_General_CI_AS NOT NULL,
	[ChangedDate] [date] NOT NULL,
	[UserId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
