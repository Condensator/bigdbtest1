CREATE TYPE [dbo].[LeaseInvestmentTracking] AS TABLE(
	[Investment] [decimal](16, 2) NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[InvestmentDate] [date] NOT NULL,
	[IsLessorOwned] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[ContractId] [bigint] NOT NULL,
	[LeaseFinanceId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
