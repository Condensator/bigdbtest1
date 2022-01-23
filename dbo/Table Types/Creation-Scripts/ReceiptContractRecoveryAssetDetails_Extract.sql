CREATE TYPE [dbo].[ReceiptContractRecoveryAssetDetails_Extract] AS TABLE(
	[ContractId] [bigint] NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[AssetId] [bigint] NULL,
	[ChargeOffId] [bigint] NULL,
	[NetWriteDownForChargeOff] [decimal](16, 2) NULL,
	[NetInvestmentWithBlended] [decimal](16, 2) NULL,
	[WriteDownId] [bigint] NULL,
	[TotalWriteDownAmount] [decimal](16, 2) NULL,
	[LeaseComponentWriteDownAmount] [decimal](16, 2) NULL,
	[NonLeaseComponentWriteDownAmount] [decimal](16, 2) NULL,
	[JobStepInstanceId] [bigint] NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
