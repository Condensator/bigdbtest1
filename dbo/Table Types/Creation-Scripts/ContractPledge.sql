CREATE TYPE [dbo].[ContractPledge] AS TABLE(
	[IsExpired] [bit] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[IsActive] [bit] NOT NULL,
	[Bank] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[BIC] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[BankAccountBGN] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[BankAccountEUR] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[PledgeReceivables] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[PledgeVehicles] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[PledgeInFavorOf] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[CascoCoverage] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[Comment] [nvarchar](2000) COLLATE Latin1_General_CI_AS NULL,
	[InterestBaseId] [bigint] NULL,
	[LoanNumberId] [bigint] NULL,
	[ContractId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
