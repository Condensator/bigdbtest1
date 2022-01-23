CREATE TYPE [dbo].[ReceivableWithholdingTaxDetail] AS TABLE(
	[TaxRate] [decimal](5, 2) NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[BasisAmount_Amount] [decimal](16, 2) NOT NULL,
	[BasisAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Tax_Amount] [decimal](16, 2) NOT NULL,
	[Tax_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Balance_Amount] [decimal](16, 2) NOT NULL,
	[Balance_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[EffectiveBalance_Amount] [decimal](16, 2) NOT NULL,
	[EffectiveBalance_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[ReceivableId] [bigint] NOT NULL,
	[WithholdingTaxCodeDetailId] [bigint] NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
