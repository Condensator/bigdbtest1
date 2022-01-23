CREATE TYPE [dbo].[ReceivableType] AS TABLE(
	[Name] [nvarchar](21) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[IsRental] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[MemoAllowed] [bit] NOT NULL,
	[CashBasedAllowed] [bit] NOT NULL,
	[LeaseBased] [bit] NOT NULL,
	[LoanBased] [bit] NOT NULL,
	[InvoicePreferenceAllowed] [bit] NOT NULL,
	[EARApplicable] [nvarchar](8) COLLATE Latin1_General_CI_AS NOT NULL,
	[GLTransactionTypeId] [bigint] NOT NULL,
	[SyndicationGLTransactionTypeId] [bigint] NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
