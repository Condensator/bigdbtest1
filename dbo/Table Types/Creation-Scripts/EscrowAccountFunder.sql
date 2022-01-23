CREATE TYPE [dbo].[EscrowAccountFunder] AS TABLE(
	[FundingFor] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[FundingAmount_Amount] [decimal](16, 2) NULL,
	[FundingAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[DisbursementType] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[DisbursementNumber] [bigint] NULL,
	[InvoiceNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[PayeeName] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[Comments] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[FederalReferenceNumber] [nvarchar](20) COLLATE Latin1_General_CI_AS NULL,
	[FinalFunding] [bit] NOT NULL,
	[EscrowAccountId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
