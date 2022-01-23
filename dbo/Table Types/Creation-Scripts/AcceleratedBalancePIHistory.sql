CREATE TYPE [dbo].[AcceleratedBalancePIHistory] AS TABLE(
	[Asof] [date] NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[AccruedInterest_Amount] [decimal](16, 2) NULL,
	[AccruedInterest_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[PerDiem_Amount] [decimal](16, 2) NULL,
	[PerDiem_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[Principal_Amount] [decimal](16, 2) NULL,
	[Principal_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[TotalPAndI_Amount] [decimal](16, 2) NULL,
	[TotalPAndI_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[IsLease] [bit] NOT NULL,
	[IsJudgement] [bit] NOT NULL,
	[InterestAccrualDetailRowNo] [bigint] NOT NULL,
	[AcceleratedBalanceDetailId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
