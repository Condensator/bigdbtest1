CREATE TYPE [dbo].[AcceleratedBalanceCredit] AS TABLE(
	[CreditDescription] [nvarchar](20) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[DateApplied] [date] NULL,
	[CheckNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[Amount_Amount] [decimal](16, 2) NOT NULL,
	[Amount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[IsLease] [bit] NOT NULL,
	[IsJudgement] [bit] NOT NULL,
	[AcceleratedBalanceDetailId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
