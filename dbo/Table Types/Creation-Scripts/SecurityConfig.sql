CREATE TYPE [dbo].[SecurityConfig] AS TABLE(
	[PasswordHistoryCount] [int] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[MinPasswordAgeInDays] [int] NOT NULL,
	[MaxPasswordAgeInDays] [int] NOT NULL,
	[MinPasswordLength] [int] NOT NULL,
	[AccountLockoutThreshold] [int] NOT NULL,
	[AccountLockoutDurationInMins] [int] NOT NULL,
	[ShowTracer] [bit] NOT NULL,
	[NoOfSecurityQuestions] [nvarchar](5) COLLATE Latin1_General_CI_AS NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
