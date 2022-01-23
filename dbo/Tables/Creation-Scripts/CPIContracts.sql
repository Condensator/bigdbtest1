SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CPIContracts](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Number] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[EntityType] [nvarchar](8) COLLATE Latin1_General_CI_AS NOT NULL,
	[Description] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[CommencementDate] [date] NOT NULL,
	[NextStartDate] [date] NULL,
	[BaseFrequency] [nvarchar](13) COLLATE Latin1_General_CI_AS NOT NULL,
	[BasePaymentFrequencyDays] [int] NOT NULL,
	[OverageFrequency] [nvarchar](13) COLLATE Latin1_General_CI_AS NOT NULL,
	[OveragePaymentFrequencyDays] [int] NOT NULL,
	[DueDay] [int] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[TerminationDate] [date] NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[CustomerId] [bigint] NULL,
	[LegalEntityId] [bigint] NOT NULL,
	[ContractId] [bigint] NULL,
	[RemitToId] [bigint] NOT NULL,
	[BillToId] [bigint] NOT NULL,
	[BaseBillingReceivableCodeId] [bigint] NULL,
	[OverageReceivableCodeId] [bigint] NULL,
	[AdminFeeReceivableCodeId] [bigint] NULL,
	[CurrencyId] [bigint] NULL,
	[InstrumentTypeId] [bigint] NOT NULL,
	[LineofBusinessId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[CostCenterId] [bigint] NOT NULL,
	[IsInventory] [bit] NOT NULL,
	[BasePassThroughPercentage] [int] NULL,
	[OveragePassThroughPercentage] [int] NULL,
	[BasePayableCodeId] [bigint] NULL,
	[OveragePayableCodeId] [bigint] NULL,
	[PassThroughVendorId] [bigint] NULL,
	[PassThroughRemitToId] [bigint] NULL,
	[OveragePayableWithholdingTaxRate] [decimal](5, 2) NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CPIContracts]  WITH CHECK ADD  CONSTRAINT [ECPIContract_AdminFeeReceivableCode] FOREIGN KEY([AdminFeeReceivableCodeId])
REFERENCES [dbo].[ReceivableCodes] ([Id])
GO
ALTER TABLE [dbo].[CPIContracts] CHECK CONSTRAINT [ECPIContract_AdminFeeReceivableCode]
GO
ALTER TABLE [dbo].[CPIContracts]  WITH CHECK ADD  CONSTRAINT [ECPIContract_BaseBillingReceivableCode] FOREIGN KEY([BaseBillingReceivableCodeId])
REFERENCES [dbo].[ReceivableCodes] ([Id])
GO
ALTER TABLE [dbo].[CPIContracts] CHECK CONSTRAINT [ECPIContract_BaseBillingReceivableCode]
GO
ALTER TABLE [dbo].[CPIContracts]  WITH CHECK ADD  CONSTRAINT [ECPIContract_BasePayableCode] FOREIGN KEY([BasePayableCodeId])
REFERENCES [dbo].[PayableCodes] ([Id])
GO
ALTER TABLE [dbo].[CPIContracts] CHECK CONSTRAINT [ECPIContract_BasePayableCode]
GO
ALTER TABLE [dbo].[CPIContracts]  WITH CHECK ADD  CONSTRAINT [ECPIContract_BillTo] FOREIGN KEY([BillToId])
REFERENCES [dbo].[BillToes] ([Id])
GO
ALTER TABLE [dbo].[CPIContracts] CHECK CONSTRAINT [ECPIContract_BillTo]
GO
ALTER TABLE [dbo].[CPIContracts]  WITH CHECK ADD  CONSTRAINT [ECPIContract_Contract] FOREIGN KEY([ContractId])
REFERENCES [dbo].[Contracts] ([Id])
GO
ALTER TABLE [dbo].[CPIContracts] CHECK CONSTRAINT [ECPIContract_Contract]
GO
ALTER TABLE [dbo].[CPIContracts]  WITH CHECK ADD  CONSTRAINT [ECPIContract_CostCenter] FOREIGN KEY([CostCenterId])
REFERENCES [dbo].[CostCenterConfigs] ([Id])
GO
ALTER TABLE [dbo].[CPIContracts] CHECK CONSTRAINT [ECPIContract_CostCenter]
GO
ALTER TABLE [dbo].[CPIContracts]  WITH CHECK ADD  CONSTRAINT [ECPIContract_Currency] FOREIGN KEY([CurrencyId])
REFERENCES [dbo].[Currencies] ([Id])
GO
ALTER TABLE [dbo].[CPIContracts] CHECK CONSTRAINT [ECPIContract_Currency]
GO
ALTER TABLE [dbo].[CPIContracts]  WITH CHECK ADD  CONSTRAINT [ECPIContract_Customer] FOREIGN KEY([CustomerId])
REFERENCES [dbo].[Customers] ([Id])
GO
ALTER TABLE [dbo].[CPIContracts] CHECK CONSTRAINT [ECPIContract_Customer]
GO
ALTER TABLE [dbo].[CPIContracts]  WITH CHECK ADD  CONSTRAINT [ECPIContract_InstrumentType] FOREIGN KEY([InstrumentTypeId])
REFERENCES [dbo].[InstrumentTypes] ([Id])
GO
ALTER TABLE [dbo].[CPIContracts] CHECK CONSTRAINT [ECPIContract_InstrumentType]
GO
ALTER TABLE [dbo].[CPIContracts]  WITH CHECK ADD  CONSTRAINT [ECPIContract_LegalEntity] FOREIGN KEY([LegalEntityId])
REFERENCES [dbo].[LegalEntities] ([Id])
GO
ALTER TABLE [dbo].[CPIContracts] CHECK CONSTRAINT [ECPIContract_LegalEntity]
GO
ALTER TABLE [dbo].[CPIContracts]  WITH CHECK ADD  CONSTRAINT [ECPIContract_LineofBusiness] FOREIGN KEY([LineofBusinessId])
REFERENCES [dbo].[LineofBusinesses] ([Id])
GO
ALTER TABLE [dbo].[CPIContracts] CHECK CONSTRAINT [ECPIContract_LineofBusiness]
GO
ALTER TABLE [dbo].[CPIContracts]  WITH CHECK ADD  CONSTRAINT [ECPIContract_OveragePayableCode] FOREIGN KEY([OveragePayableCodeId])
REFERENCES [dbo].[PayableCodes] ([Id])
GO
ALTER TABLE [dbo].[CPIContracts] CHECK CONSTRAINT [ECPIContract_OveragePayableCode]
GO
ALTER TABLE [dbo].[CPIContracts]  WITH CHECK ADD  CONSTRAINT [ECPIContract_OverageReceivableCode] FOREIGN KEY([OverageReceivableCodeId])
REFERENCES [dbo].[ReceivableCodes] ([Id])
GO
ALTER TABLE [dbo].[CPIContracts] CHECK CONSTRAINT [ECPIContract_OverageReceivableCode]
GO
ALTER TABLE [dbo].[CPIContracts]  WITH CHECK ADD  CONSTRAINT [ECPIContract_PassThroughRemitTo] FOREIGN KEY([PassThroughRemitToId])
REFERENCES [dbo].[RemitToes] ([Id])
GO
ALTER TABLE [dbo].[CPIContracts] CHECK CONSTRAINT [ECPIContract_PassThroughRemitTo]
GO
ALTER TABLE [dbo].[CPIContracts]  WITH CHECK ADD  CONSTRAINT [ECPIContract_PassThroughVendor] FOREIGN KEY([PassThroughVendorId])
REFERENCES [dbo].[Vendors] ([Id])
GO
ALTER TABLE [dbo].[CPIContracts] CHECK CONSTRAINT [ECPIContract_PassThroughVendor]
GO
ALTER TABLE [dbo].[CPIContracts]  WITH CHECK ADD  CONSTRAINT [ECPIContract_RemitTo] FOREIGN KEY([RemitToId])
REFERENCES [dbo].[RemitToes] ([Id])
GO
ALTER TABLE [dbo].[CPIContracts] CHECK CONSTRAINT [ECPIContract_RemitTo]
GO
