CREATE TYPE [dbo].[LoanIncomeAmortJobExtract] AS TABLE(
	[LoanFinanceId] [bigint] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[SequenceNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[ContractId] [bigint] NOT NULL,
	[LegalEntityId] [bigint] NOT NULL,
	[InvoiceLeadDays] [int] NOT NULL,
	[TaskChunkServiceInstanceId] [bigint] NULL,
	[JobInstanceId] [bigint] NOT NULL,
	[IsSubmitted] [bit] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
