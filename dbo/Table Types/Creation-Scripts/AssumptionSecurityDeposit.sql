CREATE TYPE [dbo].[AssumptionSecurityDeposit] AS TABLE(
	[SecurityDepositAmount_Amount] [decimal](16, 2) NOT NULL,
	[SecurityDepositAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[TransferToNewCustomer_Amount] [decimal](16, 2) NOT NULL,
	[TransferToNewCustomer_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[BalanceWithOldCustomer_Amount] [decimal](16, 2) NOT NULL,
	[BalanceWithOldCustomer_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[SecurityDepositId] [bigint] NOT NULL,
	[AssumptionId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
