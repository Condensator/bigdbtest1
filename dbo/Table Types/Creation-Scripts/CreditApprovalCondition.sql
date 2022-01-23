CREATE TYPE [dbo].[CreditApprovalCondition] AS TABLE(
	[IsActive] [bit] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[CreditApprovalCondition] [nvarchar](1000) COLLATE Latin1_General_CI_AS NULL,
	[ApprovalConditionConfigId] [bigint] NULL,
	[CreditDecisionId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
