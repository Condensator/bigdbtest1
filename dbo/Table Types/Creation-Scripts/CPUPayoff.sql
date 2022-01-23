CREATE TYPE [dbo].[CPUPayoff] AS TABLE(
	[QuoteName] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[IsFullPayoff] [bit] NOT NULL,
	[PayoffDate] [date] NOT NULL,
	[Status] [nvarchar](9) COLLATE Latin1_General_CI_AS NOT NULL,
	[LeasePayoffQuoteNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[CPUContractId] [bigint] NOT NULL,
	[ContractAmendmentReasonCodeId] [bigint] NULL,
	[OldCPUFinanceId] [bigint] NOT NULL,
	[CPUFinanceId] [bigint] NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
