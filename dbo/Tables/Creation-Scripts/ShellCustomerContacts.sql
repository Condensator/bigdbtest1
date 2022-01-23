SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ShellCustomerContacts](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[SFDCContactId] [nvarchar](30) COLLATE Latin1_General_CI_AS NOT NULL,
	[UniqueIdentifier] [nvarchar](30) COLLATE Latin1_General_CI_AS NOT NULL,
	[Prefix] [nvarchar](10) COLLATE Latin1_General_CI_AS NULL,
	[FirstName] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[MiddleName] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[LastName] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[PhoneNumber1] [nvarchar](15) COLLATE Latin1_General_CI_AS NULL,
	[ExtensionNumber1] [nvarchar](5) COLLATE Latin1_General_CI_AS NULL,
	[MobilePhoneNumber] [nvarchar](15) COLLATE Latin1_General_CI_AS NULL,
	[FaxNumber] [nvarchar](15) COLLATE Latin1_General_CI_AS NULL,
	[EMailId] [nvarchar](70) COLLATE Latin1_General_CI_AS NULL,
	[SocialSecurityNumber] [nvarchar](18) COLLATE Latin1_General_CI_AS NULL,
	[DateOfBirth] [date] NULL,
	[IsShellCustomerContactCreated] [bit] NOT NULL,
	[LWSystemId] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
