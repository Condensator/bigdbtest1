CREATE TYPE [dbo].[QuoteRequestCustomer] AS TABLE(
	[IsCreateCustomer] [bit] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[FirstName] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[LastName] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[IsCorporate] [bit] NOT NULL,
	[IsSoleProprietor] [bit] NOT NULL,
	[EGNNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[EIKNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[Email] [nvarchar](70) COLLATE Latin1_General_CI_AS NOT NULL,
	[PhoneNumber] [nvarchar](15) COLLATE Latin1_General_CI_AS NOT NULL,
	[Comments] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[CompanyName] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[CustomerId] [bigint] NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
