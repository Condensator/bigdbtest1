CREATE TYPE [dbo].[UserFactorAuthentication] AS TABLE(
	[LoginName] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[FactorProvider] [nvarchar](5) COLLATE Latin1_General_CI_AS NULL,
	[IsUserRegistrationRequired] [bit] NOT NULL,
	[Email] [nvarchar](70) COLLATE Latin1_General_CI_AS NULL,
	[EmailVerified] [bit] NOT NULL,
	[PhoneNumber] [nvarchar](15) COLLATE Latin1_General_CI_AS NULL,
	[PhoneVerified] [bit] NOT NULL,
	[SecretKey] [nvarchar](65) COLLATE Latin1_General_CI_AS NULL,
	[DeviceVerified] [bit] NOT NULL,
	[EffectiveDate] [date] NULL,
	[ExpiryDate] [date] NULL,
	[FailureCounter] [int] NULL,
	[SecurityStamp] [nvarchar](1000) COLLATE Latin1_General_CI_AS NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
