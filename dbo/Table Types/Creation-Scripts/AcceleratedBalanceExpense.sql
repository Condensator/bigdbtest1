CREATE TYPE [dbo].[AcceleratedBalanceExpense] AS TABLE(
	[ExpenseType] [nvarchar](26) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[Date] [date] NULL,
	[WaivedAmount_Amount] [decimal](16, 2) NOT NULL,
	[WaivedAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[AmountDue_Amount] [decimal](16, 2) NOT NULL,
	[AmountDue_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[IsLease] [bit] NOT NULL,
	[IsJudgement] [bit] NOT NULL,
	[Payee] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[Description] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[AcceleratedBalanceDetailId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
