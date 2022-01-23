SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ReceiptContractRecoveryDetails_Extract](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[ContractId] [bigint] NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ContractType] [nvarchar](14) COLLATE Latin1_General_CI_AS NULL,
	[ChargeOffId] [bigint] NULL,
	[TotalChargeOffAmount] [decimal](16, 2) NULL,
	[TotalRecoveryAmount] [decimal](16, 2) NULL,
	[ChargeOffReasonCodeConfigId] [bigint] NULL,
	[NetInvestmentWithBlended] [decimal](16, 2) NULL,
	[WriteDownId] [bigint] NULL,
	[TotalWriteDownAmount] [decimal](16, 2) NULL,
	[TotalRecoveryAmountForWriteDown] [decimal](16, 2) NULL,
	[NetWriteDown] [decimal](16, 2) NULL,
	[WriteDownGLTemplateId] [bigint] NULL,
	[RecoveryGLTemplateId] [bigint] NULL,
	[RecoveryReceivableCodeId] [bigint] NULL,
	[WriteDownDate] [date] NULL,
	[WriteDownReason] [nvarchar](18) COLLATE Latin1_General_CI_AS NULL,
	[JobStepInstanceId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[ChargeOffGLTemplateId] [bigint] NULL,
	[LeaseFinanceId] [bigint] NULL,
	[LoanFinanceId] [bigint] NULL,
	[TotalLeaseComponentChargeOffAmount] [decimal](16, 2) NULL,
	[TotalNonLeaseComponentChargeOffAmount] [decimal](16, 2) NULL,
	[TotalLeaseComponentRecoveryAmount] [decimal](16, 2) NULL,
	[TotalNonLeaseComponentRecoveryAmount] [decimal](16, 2) NULL,
	[TotalLeaseComponentGainAmount] [decimal](16, 2) NULL,
	[TotalNonLeaseComponentGainAmount] [decimal](16, 2) NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
