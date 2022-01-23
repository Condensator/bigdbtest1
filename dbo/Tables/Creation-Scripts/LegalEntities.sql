SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LegalEntities](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[LegalEntityNumber] [nvarchar](20) COLLATE Latin1_General_CI_AS NOT NULL,
	[GLSegmentValue] [nvarchar](12) COLLATE Latin1_General_CI_AS NOT NULL,
	[FiscalYearBeginMonthNo] [nvarchar](9) COLLATE Latin1_General_CI_AS NOT NULL,
	[TaxFiscalYearBeginMonthNo] [nvarchar](9) COLLATE Latin1_General_CI_AS NOT NULL,
	[Status] [nvarchar](8) COLLATE Latin1_General_CI_AS NOT NULL,
	[ActivationDate] [date] NULL,
	[DeactivationDate] [date] NULL,
	[IncorporationDate] [date] NULL,
	[TaxPayer] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[OrganizationID] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[CurrencyCode] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[TaxRemittancePreference] [nvarchar](12) COLLATE Latin1_General_CI_AS NOT NULL,
	[GSTId] [nvarchar](15) COLLATE Latin1_General_CI_AS NULL,
	[LessorWebAddress] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[CostCenter] [nvarchar](12) COLLATE Latin1_General_CI_AS NULL,
	[GLAccountNumber] [nvarchar](12) COLLATE Latin1_General_CI_AS NULL,
	[NonUSDeferredTaxAccountNumber] [nvarchar](12) COLLATE Latin1_General_CI_AS MASKED WITH (FUNCTION = 'default()') NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[TaxDepBasisCurrencyId] [bigint] NULL,
	[CurrencyId] [bigint] NOT NULL,
	[GLConfigurationId] [bigint] NOT NULL,
	[IncorporationStateId] [bigint] NOT NULL,
	[ParentId] [bigint] NULL,
	[BusinessTypeId] [bigint] NOT NULL,
	[ReceiptHierarchyTemplateId] [bigint] NULL,
	[NonAccrualRuleTemplateId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[LateFeeApproach] [nvarchar](12) COLLATE Latin1_General_CI_AS NULL,
	[ThresholdDays] [int] NULL,
	[TaxID_CT] [varbinary](48) NULL,
	[PSTQSTId] [nvarchar](15) COLLATE Latin1_General_CI_AS NULL,
	[TaxAssessmentLevel] [nvarchar](8) COLLATE Latin1_General_CI_AS NULL,
	[BusinessCalendarId] [bigint] NULL,
	[AccountingStandard] [nvarchar](12) COLLATE Latin1_General_CI_AS NOT NULL,
	[InvoiceDueDateCalculation] [nvarchar](19) COLLATE Latin1_General_CI_AS NOT NULL,
	[BusinessUnitId] [bigint] NOT NULL,
	[ReAccrualRuleTemplateId] [bigint] NULL,
	[IsAssessSalesTaxAtSKULevel] [bit] NOT NULL,
	[SupportsVAT] [bit] NOT NULL,
	[ACHFailureLimit] [int] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[LegalEntities]  WITH CHECK ADD  CONSTRAINT [ELegalEntity_BusinessCalendar] FOREIGN KEY([BusinessCalendarId])
REFERENCES [dbo].[BusinessCalendars] ([Id])
GO
ALTER TABLE [dbo].[LegalEntities] CHECK CONSTRAINT [ELegalEntity_BusinessCalendar]
GO
ALTER TABLE [dbo].[LegalEntities]  WITH CHECK ADD  CONSTRAINT [ELegalEntity_BusinessType] FOREIGN KEY([BusinessTypeId])
REFERENCES [dbo].[BusinessTypes] ([Id])
GO
ALTER TABLE [dbo].[LegalEntities] CHECK CONSTRAINT [ELegalEntity_BusinessType]
GO
ALTER TABLE [dbo].[LegalEntities]  WITH CHECK ADD  CONSTRAINT [ELegalEntity_BusinessUnit] FOREIGN KEY([BusinessUnitId])
REFERENCES [dbo].[BusinessUnits] ([Id])
GO
ALTER TABLE [dbo].[LegalEntities] CHECK CONSTRAINT [ELegalEntity_BusinessUnit]
GO
ALTER TABLE [dbo].[LegalEntities]  WITH CHECK ADD  CONSTRAINT [ELegalEntity_Currency] FOREIGN KEY([CurrencyId])
REFERENCES [dbo].[Currencies] ([Id])
GO
ALTER TABLE [dbo].[LegalEntities] CHECK CONSTRAINT [ELegalEntity_Currency]
GO
ALTER TABLE [dbo].[LegalEntities]  WITH CHECK ADD  CONSTRAINT [ELegalEntity_GLConfiguration] FOREIGN KEY([GLConfigurationId])
REFERENCES [dbo].[GLConfigurations] ([Id])
GO
ALTER TABLE [dbo].[LegalEntities] CHECK CONSTRAINT [ELegalEntity_GLConfiguration]
GO
ALTER TABLE [dbo].[LegalEntities]  WITH CHECK ADD  CONSTRAINT [ELegalEntity_IncorporationState] FOREIGN KEY([IncorporationStateId])
REFERENCES [dbo].[States] ([Id])
GO
ALTER TABLE [dbo].[LegalEntities] CHECK CONSTRAINT [ELegalEntity_IncorporationState]
GO
ALTER TABLE [dbo].[LegalEntities]  WITH CHECK ADD  CONSTRAINT [ELegalEntity_NonAccrualRuleTemplate] FOREIGN KEY([NonAccrualRuleTemplateId])
REFERENCES [dbo].[NonAccrualRuleTemplates] ([Id])
GO
ALTER TABLE [dbo].[LegalEntities] CHECK CONSTRAINT [ELegalEntity_NonAccrualRuleTemplate]
GO
ALTER TABLE [dbo].[LegalEntities]  WITH CHECK ADD  CONSTRAINT [ELegalEntity_Parent] FOREIGN KEY([ParentId])
REFERENCES [dbo].[LegalEntities] ([Id])
GO
ALTER TABLE [dbo].[LegalEntities] CHECK CONSTRAINT [ELegalEntity_Parent]
GO
ALTER TABLE [dbo].[LegalEntities]  WITH CHECK ADD  CONSTRAINT [ELegalEntity_ReAccrualRuleTemplate] FOREIGN KEY([ReAccrualRuleTemplateId])
REFERENCES [dbo].[ReAccrualRuleTemplates] ([Id])
GO
ALTER TABLE [dbo].[LegalEntities] CHECK CONSTRAINT [ELegalEntity_ReAccrualRuleTemplate]
GO
ALTER TABLE [dbo].[LegalEntities]  WITH CHECK ADD  CONSTRAINT [ELegalEntity_ReceiptHierarchyTemplate] FOREIGN KEY([ReceiptHierarchyTemplateId])
REFERENCES [dbo].[ReceiptHierarchyTemplates] ([Id])
GO
ALTER TABLE [dbo].[LegalEntities] CHECK CONSTRAINT [ELegalEntity_ReceiptHierarchyTemplate]
GO
ALTER TABLE [dbo].[LegalEntities]  WITH CHECK ADD  CONSTRAINT [ELegalEntity_TaxDepBasisCurrency] FOREIGN KEY([TaxDepBasisCurrencyId])
REFERENCES [dbo].[Currencies] ([Id])
GO
ALTER TABLE [dbo].[LegalEntities] CHECK CONSTRAINT [ELegalEntity_TaxDepBasisCurrency]
GO
