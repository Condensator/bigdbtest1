CREATE TYPE [dbo].[NBVWithBlendedCalculatorInput] AS TABLE(
	[ContractId] [bigint] NULL,
	[ContractType] [nvarchar](30) COLLATE Latin1_General_CI_AS NULL,
	[AsofDate] [date] NULL
)
GO
