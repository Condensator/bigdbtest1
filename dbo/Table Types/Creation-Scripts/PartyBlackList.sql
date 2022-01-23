CREATE TYPE [dbo].[PartyBlackList] AS TABLE(
	[EGNOrEIKNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[CompanyName] [nvarchar](2000) COLLATE Latin1_General_CI_AS NULL,
	[FirstName] [nvarchar](2000) COLLATE Latin1_General_CI_AS NULL,
	[LastName] [nvarchar](2000) COLLATE Latin1_General_CI_AS NULL,
	[Address] [nvarchar](2000) COLLATE Latin1_General_CI_AS NULL,
	[PhoneNumber] [nvarchar](2000) COLLATE Latin1_General_CI_AS NULL,
	[Reason] [nvarchar](2000) COLLATE Latin1_General_CI_AS NOT NULL,
	[Comment] [nvarchar](2000) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
