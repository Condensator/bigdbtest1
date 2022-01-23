CREATE TYPE [dbo].[LegalEntityBankAccount] AS TABLE(
	[IsActive] [bit] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ACISCustomerNumber] [nvarchar](10) COLLATE Latin1_General_CI_AS NULL,
	[SourceofInput] [nvarchar](8) COLLATE Latin1_General_CI_AS NULL,
	[BankAccountId] [bigint] NOT NULL,
	[ACHOperatorConfigId] [bigint] NULL,
	[LegalEntityId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
