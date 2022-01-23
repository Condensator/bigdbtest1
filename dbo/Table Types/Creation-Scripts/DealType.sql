CREATE TYPE [dbo].[DealType] AS TABLE(
	[Name] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[IsLoan] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[IsIncomeTaxExempt] [bit] NOT NULL,
	[ProductType] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[ContractType] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
