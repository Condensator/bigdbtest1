CREATE TYPE [dbo].[AcceleratedBalanceEstimatedPropertyTax] AS TABLE(
	[Year] [decimal](4, 0) NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[PPTAmount_Amount] [decimal](16, 2) NOT NULL,
	[PPTAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[TaxonPPT_Amount] [decimal](16, 2) NOT NULL,
	[TaxonPPT_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[TotalPPT_Amount] [decimal](16, 2) NOT NULL,
	[TotalPPT_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[AcceleratedBalanceDetailId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
