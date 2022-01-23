CREATE TYPE [dbo].[AgencyLegalPlacementContract] AS TABLE(
	[IsActive] [bit] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[FundsReceived_Amount] [decimal](16, 2) NULL,
	[FundsReceived_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[ContractId] [bigint] NOT NULL,
	[AcceleratedBalanceDetailId] [bigint] NULL,
	[AgencyLegalPlacementId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
