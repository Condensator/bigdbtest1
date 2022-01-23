SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SecurityConfigs](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[PasswordHistoryCount] [int] NOT NULL,
	[MinPasswordAgeInDays] [int] NOT NULL,
	[MaxPasswordAgeInDays] [int] NOT NULL,
	[MinPasswordLength] [int] NOT NULL,
	[AccountLockoutThreshold] [int] NOT NULL,
	[AccountLockoutDurationInMins] [int] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RowVersion] [timestamp] NOT NULL,
	[ShowTracer] [bit] NOT NULL,
	[NoOfSecurityQuestions] [nvarchar](5) COLLATE Latin1_General_CI_AS NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
