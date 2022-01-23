CREATE TYPE [dbo].[LoanYield] AS TABLE(
	[Yield] [nvarchar](20) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[PreTaxWithoutFees] [decimal](10, 6) NOT NULL,
	[PreTaxWithFees] [decimal](10, 6) NOT NULL,
	[PostTaxWithoutFees] [decimal](10, 6) NOT NULL,
	[PostTaxWithFees] [decimal](10, 6) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[LoanFinanceId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
