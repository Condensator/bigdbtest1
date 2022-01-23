CREATE TYPE [dbo].[CPUOverageReceivableGroupInfo] AS TABLE(
	[BeginPeriodDate] [date] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[EndPeriodDate] [date] NOT NULL,
	[BaseAllowance] [bigint] NOT NULL,
	[OverageAllowance] [bigint] NOT NULL,
	[Tier] [nvarchar](9) COLLATE Latin1_General_CI_AS NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
