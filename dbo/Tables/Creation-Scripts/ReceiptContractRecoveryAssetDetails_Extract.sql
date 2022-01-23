SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ReceiptContractRecoveryAssetDetails_Extract](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[ContractId] [bigint] NULL,
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
	[JobStepInstanceId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[LeaseComponentWriteDownAmount] [decimal](16, 2) NULL,
	[NonLeaseComponentWriteDownAmount] [decimal](16, 2) NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
