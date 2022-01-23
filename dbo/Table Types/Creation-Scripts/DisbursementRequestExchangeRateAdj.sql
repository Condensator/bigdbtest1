CREATE TYPE [dbo].[DisbursementRequestExchangeRateAdj] AS TABLE(
	[Capitalized] [nvarchar](13) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[AmountPaid_Amount] [decimal](16, 2) NOT NULL,
	[AmountPaid_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Description] [nvarchar](50) COLLATE Latin1_General_CI_AS NULL,
	[FederalReferenceNumber] [nvarchar](20) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[DisbursementRequestId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
