CREATE TYPE [dbo].[LoanPaydownReversal] AS TABLE(
	[PostDate] [date] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[Comments] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[InvoiceNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[ContractId] [bigint] NOT NULL,
	[LoanPaydownId] [bigint] NOT NULL,
	[GlJournalId] [bigint] NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
