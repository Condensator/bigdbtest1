CREATE TYPE [dbo].[CreditRACQualifier] AS TABLE(
	[Type] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RuleDisplayText] [nvarchar](200) COLLATE Latin1_General_CI_AS NOT NULL,
	[ActualValue] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[RACQualifierId] [bigint] NOT NULL,
	[CreditRACId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
