CREATE TYPE [dbo].[LoanPrepaymentPenalty] AS TABLE(
	[Name] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[PrepaymentBasis] [nvarchar](19) COLLATE Latin1_General_CI_AS NULL,
	[PrepaymentPenaltyTerm] [nvarchar](23) COLLATE Latin1_General_CI_AS NULL,
	[MinimumPrepaymentMonths] [int] NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
