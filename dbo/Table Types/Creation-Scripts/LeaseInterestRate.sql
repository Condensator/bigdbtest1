CREATE TYPE [dbo].[LeaseInterestRate] AS TABLE(
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[IsPricingInterestRate] [bit] NOT NULL,
	[IsSystemGenerated] [bit] NOT NULL,
	[InterestRateDetailId] [bigint] NOT NULL,
	[ParentLeaseInterestRateId] [bigint] NULL,
	[LeaseFinanceDetailId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
