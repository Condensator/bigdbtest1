SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CPUAccountings](
	[Id] [bigint] NOT NULL,
	[LineofBusinessId] [bigint] NULL,
	[CostCenterId] [bigint] NULL,
	[BranchId] [bigint] NULL,
	[InstrumentTypeId] [bigint] NULL,
	[BaseFeeReceivableCodeId] [bigint] NULL,
	[OverageFeeReceivableCodeId] [bigint] NULL,
	[BaseFeePayableCodeId] [bigint] NULL,
	[OverageFeePayableCodeId] [bigint] NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RowVersion] [timestamp] NOT NULL,
	[BaseFeePayableWithholdingTaxRate] [decimal](5, 2) NULL,
	[OverageFeePayableWithholdingTaxRate] [decimal](5, 2) NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CPUAccountings]  WITH CHECK ADD  CONSTRAINT [ECPUAccounting_BaseFeePayableCode] FOREIGN KEY([BaseFeePayableCodeId])
REFERENCES [dbo].[PayableCodes] ([Id])
GO
ALTER TABLE [dbo].[CPUAccountings] CHECK CONSTRAINT [ECPUAccounting_BaseFeePayableCode]
GO
ALTER TABLE [dbo].[CPUAccountings]  WITH CHECK ADD  CONSTRAINT [ECPUAccounting_BaseFeeReceivableCode] FOREIGN KEY([BaseFeeReceivableCodeId])
REFERENCES [dbo].[ReceivableCodes] ([Id])
GO
ALTER TABLE [dbo].[CPUAccountings] CHECK CONSTRAINT [ECPUAccounting_BaseFeeReceivableCode]
GO
ALTER TABLE [dbo].[CPUAccountings]  WITH CHECK ADD  CONSTRAINT [ECPUAccounting_Branch] FOREIGN KEY([BranchId])
REFERENCES [dbo].[Branches] ([Id])
GO
ALTER TABLE [dbo].[CPUAccountings] CHECK CONSTRAINT [ECPUAccounting_Branch]
GO
ALTER TABLE [dbo].[CPUAccountings]  WITH CHECK ADD  CONSTRAINT [ECPUAccounting_CostCenter] FOREIGN KEY([CostCenterId])
REFERENCES [dbo].[CostCenterConfigs] ([Id])
GO
ALTER TABLE [dbo].[CPUAccountings] CHECK CONSTRAINT [ECPUAccounting_CostCenter]
GO
ALTER TABLE [dbo].[CPUAccountings]  WITH CHECK ADD  CONSTRAINT [ECPUAccounting_InstrumentType] FOREIGN KEY([InstrumentTypeId])
REFERENCES [dbo].[InstrumentTypes] ([Id])
GO
ALTER TABLE [dbo].[CPUAccountings] CHECK CONSTRAINT [ECPUAccounting_InstrumentType]
GO
ALTER TABLE [dbo].[CPUAccountings]  WITH CHECK ADD  CONSTRAINT [ECPUAccounting_LineofBusiness] FOREIGN KEY([LineofBusinessId])
REFERENCES [dbo].[LineofBusinesses] ([Id])
GO
ALTER TABLE [dbo].[CPUAccountings] CHECK CONSTRAINT [ECPUAccounting_LineofBusiness]
GO
ALTER TABLE [dbo].[CPUAccountings]  WITH CHECK ADD  CONSTRAINT [ECPUAccounting_OverageFeePayableCode] FOREIGN KEY([OverageFeePayableCodeId])
REFERENCES [dbo].[PayableCodes] ([Id])
GO
ALTER TABLE [dbo].[CPUAccountings] CHECK CONSTRAINT [ECPUAccounting_OverageFeePayableCode]
GO
ALTER TABLE [dbo].[CPUAccountings]  WITH CHECK ADD  CONSTRAINT [ECPUAccounting_OverageFeeReceivableCode] FOREIGN KEY([OverageFeeReceivableCodeId])
REFERENCES [dbo].[ReceivableCodes] ([Id])
GO
ALTER TABLE [dbo].[CPUAccountings] CHECK CONSTRAINT [ECPUAccounting_OverageFeeReceivableCode]
GO
ALTER TABLE [dbo].[CPUAccountings]  WITH CHECK ADD  CONSTRAINT [ECPUFinance_CPUAccounting] FOREIGN KEY([Id])
REFERENCES [dbo].[CPUFinances] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CPUAccountings] CHECK CONSTRAINT [ECPUFinance_CPUAccounting]
GO
