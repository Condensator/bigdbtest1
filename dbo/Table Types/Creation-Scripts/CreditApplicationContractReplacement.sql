CREATE TYPE [dbo].[CreditApplicationContractReplacement] AS TABLE(
	[IsActive] [bit] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RNIAmount_Amount] [decimal](16, 2) NULL,
	[RNIAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[ReplacementAmount_Amount] [decimal](16, 2) NULL,
	[ReplacementAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[ContractId] [bigint] NOT NULL,
	[CreditApplicationId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
