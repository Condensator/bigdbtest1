CREATE TYPE [dbo].[ContractLateFeeDetail] AS TABLE(
	[DaysLate] [int] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[InterestRate] [decimal](10, 6) NULL,
	[PayPercent] [decimal](10, 6) NULL,
	[FlatFee_Amount] [decimal](16, 2) NULL,
	[FlatFee_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[ContractLateFeeId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
