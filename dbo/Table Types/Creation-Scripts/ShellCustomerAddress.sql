CREATE TYPE [dbo].[ShellCustomerAddress] AS TABLE(
	[SFDCAddressId] [nvarchar](30) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[UniqueIdentifier] [nvarchar](30) COLLATE Latin1_General_CI_AS NULL,
	[AddressLine1] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[AddressLine2] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[AddressLine3] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[City] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[Division] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[PostalCode] [nvarchar](12) COLLATE Latin1_General_CI_AS NULL,
	[IsShellCustomerAddressCreated] [bit] NOT NULL,
	[LWSystemId] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[StateId] [bigint] NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
