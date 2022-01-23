CREATE TYPE [dbo].[RACRule] AS TABLE(
	[RuleDisplayText] [nvarchar](200) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[MinDate] [date] NULL,
	[MaxDate] [date] NULL,
	[Min] [decimal](16, 2) NULL,
	[Max] [decimal](16, 2) NULL,
	[MinNumber] [int] NULL,
	[MaxNumber] [int] NULL,
	[Percentage] [decimal](5, 2) NULL,
	[Bool] [nvarchar](5) COLLATE Latin1_General_CI_AS NULL,
	[String] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[RACRuleConfigId] [bigint] NOT NULL,
	[RACId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
