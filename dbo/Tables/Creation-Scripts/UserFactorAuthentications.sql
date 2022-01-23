SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[UserFactorAuthentications](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[LoginName] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
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
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
