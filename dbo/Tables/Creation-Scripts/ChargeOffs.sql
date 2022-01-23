SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ChargeOffs](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[ChargeOffDate] [date] NULL,
	[ChargeOffAmount_Amount] [decimal](16, 2) NULL,
	[ChargeOffAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[PostDate] [date] NULL,
	[ContractType] [nvarchar](14) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[Status] [nvarchar](20) COLLATE Latin1_General_CI_AS NULL,
	[Comment] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[IsRecovery] [bit] NOT NULL,
	[NetInvestmentWithBlended_Amount] [decimal](16, 2) NOT NULL,
	[NetInvestmentWithBlended_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[GrossWritedown_Amount] [decimal](16, 2) NOT NULL,
	[GrossWritedown_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[NetWritedown_Amount] [decimal](16, 2) NOT NULL,
	[NetWritedown_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[GLTemplateId] [bigint] NULL,
	[ContractId] [bigint] NULL,
	[ReceiptId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[ChargeOffReasonCodeConfigId] [bigint] NULL,
	[ChargeOffProcessingDate] [date] NULL,
	[LeaseComponentAmount_Amount] [decimal](16, 2) NULL,
	[LeaseComponentAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[NonLeaseComponentAmount_Amount] [decimal](16, 2) NULL,
	[NonLeaseComponentAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[LeaseComponentGain_Amount] [decimal](16, 2) NULL,
	[LeaseComponentGain_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[NonLeaseComponentGain_Amount] [decimal](16, 2) NULL,
	[NonLeaseComponentGain_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ChargeOffs]  WITH CHECK ADD  CONSTRAINT [EChargeOff_ChargeOffReasonCodeConfig] FOREIGN KEY([ChargeOffReasonCodeConfigId])
REFERENCES [dbo].[ChargeOffReasonCodeConfigs] ([Id])
GO
ALTER TABLE [dbo].[ChargeOffs] CHECK CONSTRAINT [EChargeOff_ChargeOffReasonCodeConfig]
GO
ALTER TABLE [dbo].[ChargeOffs]  WITH CHECK ADD  CONSTRAINT [EChargeOff_Contract] FOREIGN KEY([ContractId])
REFERENCES [dbo].[Contracts] ([Id])
GO
ALTER TABLE [dbo].[ChargeOffs] CHECK CONSTRAINT [EChargeOff_Contract]
GO
ALTER TABLE [dbo].[ChargeOffs]  WITH CHECK ADD  CONSTRAINT [EChargeOff_GLTemplate] FOREIGN KEY([GLTemplateId])
REFERENCES [dbo].[GLTemplates] ([Id])
GO
ALTER TABLE [dbo].[ChargeOffs] CHECK CONSTRAINT [EChargeOff_GLTemplate]
GO
ALTER TABLE [dbo].[ChargeOffs]  WITH CHECK ADD  CONSTRAINT [EChargeOff_Receipt] FOREIGN KEY([ReceiptId])
REFERENCES [dbo].[Receipts] ([Id])
GO
ALTER TABLE [dbo].[ChargeOffs] CHECK CONSTRAINT [EChargeOff_Receipt]
GO
