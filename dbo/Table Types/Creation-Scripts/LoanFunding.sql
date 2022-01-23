CREATE TYPE [dbo].[LoanFunding] AS TABLE(
	[RowNumber] [int] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[UsePayDate] [bit] NOT NULL,
	[IsEligibleForInterimBilling] [bit] NOT NULL,
	[IsApproved] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[Type] [nvarchar](21) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsNewlyAdded] [bit] NOT NULL,
	[FundingId] [bigint] NULL,
	[LoanFinanceId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
