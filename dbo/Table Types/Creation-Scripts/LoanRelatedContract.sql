CREATE TYPE [dbo].[LoanRelatedContract] AS TABLE(
	[IsActive] [bit] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[IsParent] [bit] NOT NULL,
	[ReasonCode] [nvarchar](14) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsInclude] [bit] NOT NULL,
	[ScheduleDate] [date] NULL,
	[MasterDate] [date] NULL,
	[ContractId] [bigint] NOT NULL,
	[LoanFinanceId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
