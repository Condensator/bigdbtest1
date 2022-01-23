SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LeveragedLeases](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[AmortDocument_Source] [nvarchar](250) COLLATE Latin1_General_CI_AS NOT NULL,
	[AmortDocument_Type] [nvarchar](5) COLLATE Latin1_General_CI_AS NOT NULL,
	[AmortDocument_Content] [varbinary](82) NOT NULL,
	[CommencementDate] [date] NULL,
	[MaturityDate] [date] NULL,
	[Term] [decimal](10, 6) NOT NULL,
	[EquipmentCost_Amount] [decimal](24, 2) NULL,
	[EquipmentCost_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[ResidualValue_Amount] [decimal](24, 2) NULL,
	[ResidualValue_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[LongTermDebt_Amount] [decimal](24, 2) NULL,
	[LongTermDebt_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[EquityInvestment_Amount] [decimal](24, 2) NULL,
	[EquityInvestment_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[IDC_Amount] [decimal](24, 2) NULL,
	[IDC_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[RentalsReceivable_Amount] [decimal](24, 2) NULL,
	[RentalsReceivable_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[Debt_Amount] [decimal](24, 2) NULL,
	[Debt_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[AssetDescription] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[PostDate] [date] NULL,
	[Status] [nvarchar](12) COLLATE Latin1_General_CI_AS NOT NULL,
	[HoldingStatus] [nvarchar](13) COLLATE Latin1_General_CI_AS NOT NULL,
	[AcquisitionId] [nvarchar](12) COLLATE Latin1_General_CI_AS NULL,
	[IsCurrent] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ContractId] [bigint] NOT NULL,
	[LegalEntityId] [bigint] NOT NULL,
	[CustomerId] [bigint] NOT NULL,
	[ContractOriginationId] [bigint] NOT NULL,
	[IncomeGLTemplateId] [bigint] NULL,
	[BookingGLTemplateId] [bigint] NULL,
	[RentalReceivableCodeId] [bigint] NULL,
	[LeveragedLeasePartnerId] [bigint] NOT NULL,
	[ReferenceLeaseId] [bigint] NULL,
	[InstrumentTypeId] [bigint] NULL,
	[LineofBusinessId] [bigint] NOT NULL,
	[AssetTypeId] [bigint] NULL,
	[DeferredTaxGLTemplateId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[CostCenterId] [bigint] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[LeveragedLeases]  WITH CHECK ADD  CONSTRAINT [ELeveragedLease_AssetType] FOREIGN KEY([AssetTypeId])
REFERENCES [dbo].[AssetTypes] ([Id])
GO
ALTER TABLE [dbo].[LeveragedLeases] CHECK CONSTRAINT [ELeveragedLease_AssetType]
GO
ALTER TABLE [dbo].[LeveragedLeases]  WITH CHECK ADD  CONSTRAINT [ELeveragedLease_BookingGLTemplate] FOREIGN KEY([BookingGLTemplateId])
REFERENCES [dbo].[GLTemplates] ([Id])
GO
ALTER TABLE [dbo].[LeveragedLeases] CHECK CONSTRAINT [ELeveragedLease_BookingGLTemplate]
GO
ALTER TABLE [dbo].[LeveragedLeases]  WITH CHECK ADD  CONSTRAINT [ELeveragedLease_Contract] FOREIGN KEY([ContractId])
REFERENCES [dbo].[Contracts] ([Id])
GO
ALTER TABLE [dbo].[LeveragedLeases] CHECK CONSTRAINT [ELeveragedLease_Contract]
GO
ALTER TABLE [dbo].[LeveragedLeases]  WITH CHECK ADD  CONSTRAINT [ELeveragedLease_ContractOrigination] FOREIGN KEY([ContractOriginationId])
REFERENCES [dbo].[ContractOriginations] ([Id])
GO
ALTER TABLE [dbo].[LeveragedLeases] CHECK CONSTRAINT [ELeveragedLease_ContractOrigination]
GO
ALTER TABLE [dbo].[LeveragedLeases]  WITH CHECK ADD  CONSTRAINT [ELeveragedLease_CostCenter] FOREIGN KEY([CostCenterId])
REFERENCES [dbo].[CostCenterConfigs] ([Id])
GO
ALTER TABLE [dbo].[LeveragedLeases] CHECK CONSTRAINT [ELeveragedLease_CostCenter]
GO
ALTER TABLE [dbo].[LeveragedLeases]  WITH CHECK ADD  CONSTRAINT [ELeveragedLease_Customer] FOREIGN KEY([CustomerId])
REFERENCES [dbo].[Customers] ([Id])
GO
ALTER TABLE [dbo].[LeveragedLeases] CHECK CONSTRAINT [ELeveragedLease_Customer]
GO
ALTER TABLE [dbo].[LeveragedLeases]  WITH CHECK ADD  CONSTRAINT [ELeveragedLease_DeferredTaxGLTemplate] FOREIGN KEY([DeferredTaxGLTemplateId])
REFERENCES [dbo].[GLTemplates] ([Id])
GO
ALTER TABLE [dbo].[LeveragedLeases] CHECK CONSTRAINT [ELeveragedLease_DeferredTaxGLTemplate]
GO
ALTER TABLE [dbo].[LeveragedLeases]  WITH CHECK ADD  CONSTRAINT [ELeveragedLease_IncomeGLTemplate] FOREIGN KEY([IncomeGLTemplateId])
REFERENCES [dbo].[GLTemplates] ([Id])
GO
ALTER TABLE [dbo].[LeveragedLeases] CHECK CONSTRAINT [ELeveragedLease_IncomeGLTemplate]
GO
ALTER TABLE [dbo].[LeveragedLeases]  WITH CHECK ADD  CONSTRAINT [ELeveragedLease_InstrumentType] FOREIGN KEY([InstrumentTypeId])
REFERENCES [dbo].[InstrumentTypes] ([Id])
GO
ALTER TABLE [dbo].[LeveragedLeases] CHECK CONSTRAINT [ELeveragedLease_InstrumentType]
GO
ALTER TABLE [dbo].[LeveragedLeases]  WITH CHECK ADD  CONSTRAINT [ELeveragedLease_LegalEntity] FOREIGN KEY([LegalEntityId])
REFERENCES [dbo].[LegalEntities] ([Id])
GO
ALTER TABLE [dbo].[LeveragedLeases] CHECK CONSTRAINT [ELeveragedLease_LegalEntity]
GO
ALTER TABLE [dbo].[LeveragedLeases]  WITH CHECK ADD  CONSTRAINT [ELeveragedLease_LeveragedLeasePartner] FOREIGN KEY([LeveragedLeasePartnerId])
REFERENCES [dbo].[Funders] ([Id])
GO
ALTER TABLE [dbo].[LeveragedLeases] CHECK CONSTRAINT [ELeveragedLease_LeveragedLeasePartner]
GO
ALTER TABLE [dbo].[LeveragedLeases]  WITH CHECK ADD  CONSTRAINT [ELeveragedLease_LineofBusiness] FOREIGN KEY([LineofBusinessId])
REFERENCES [dbo].[LineofBusinesses] ([Id])
GO
ALTER TABLE [dbo].[LeveragedLeases] CHECK CONSTRAINT [ELeveragedLease_LineofBusiness]
GO
ALTER TABLE [dbo].[LeveragedLeases]  WITH CHECK ADD  CONSTRAINT [ELeveragedLease_ReferenceLease] FOREIGN KEY([ReferenceLeaseId])
REFERENCES [dbo].[Contracts] ([Id])
GO
ALTER TABLE [dbo].[LeveragedLeases] CHECK CONSTRAINT [ELeveragedLease_ReferenceLease]
GO
ALTER TABLE [dbo].[LeveragedLeases]  WITH CHECK ADD  CONSTRAINT [ELeveragedLease_RentalReceivableCode] FOREIGN KEY([RentalReceivableCodeId])
REFERENCES [dbo].[ReceivableCodes] ([Id])
GO
ALTER TABLE [dbo].[LeveragedLeases] CHECK CONSTRAINT [ELeveragedLease_RentalReceivableCode]
GO
