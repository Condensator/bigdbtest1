CREATE TYPE [dbo].[InvoiceJobErrorSummary] AS TABLE(
	[JobStepId] [bigint] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[SourceJobStepInstanceId] [bigint] NOT NULL,
	[RunJobStepInstanceId] [bigint] NOT NULL,
	[BillToId] [bigint] NOT NULL,
	[NextAction] [nvarchar](27) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
