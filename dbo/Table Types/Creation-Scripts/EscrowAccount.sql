CREATE TYPE [dbo].[EscrowAccount] AS TABLE(
	[EscrowAccountNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[EscrowAccountOpenDate] [date] NULL,
	[EscrowAgentContactName] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[EscrowAgentContactPhoneNumber] [nvarchar](15) COLLATE Latin1_General_CI_AS NULL,
	[EscrowAgentEmail] [nvarchar](1000) COLLATE Latin1_General_CI_AS NULL,
	[EscrowAgentNameCompany] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[SalesRepName] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[Comments] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[AccountStatus] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
