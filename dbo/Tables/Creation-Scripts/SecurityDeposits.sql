SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SecurityDeposits](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[DepositType] [nvarchar](17) COLLATE Latin1_General_CI_AS NOT NULL,
	[EntityType] [nvarchar](2) COLLATE Latin1_General_CI_AS NOT NULL,
	[Amount_Amount] [decimal](16, 2) NOT NULL,
	[Amount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[DueDate] [date] NOT NULL,
	[InvoiceReceivableGroupingOption] [nvarchar](8) COLLATE Latin1_General_CI_AS NOT NULL,
	[PostDate] [date] NOT NULL,
	[InvoiceComment] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[CurrencyId] [bigint] NOT NULL,
	[LineofBusinessId] [bigint] NULL,
	[InstrumentTypeId] [bigint] NULL,
	[ContractId] [bigint] NULL,
	[LegalEntityId] [bigint] NOT NULL,
	[CustomerId] [bigint] NOT NULL,
	[ReceivableCodeId] [bigint] NOT NULL,
	[LocationId] [bigint] NULL,
	[BillToId] [bigint] NOT NULL,
	[RemitToId] [bigint] NOT NULL,
	[ReceivableId] [bigint] NULL,
	[ReceiptGLTemplateId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[HoldToMaturity] [bit] NOT NULL,
	[NumberOfMonthsRetained] [int] NULL,
	[HoldEndDate] [date] NULL,
	[CostCenterId] [bigint] NOT NULL,
	[IsServiced] [bit] NOT NULL,
	[IsCollected] [bit] NOT NULL,
	[IsPrivateLabel] [bit] NOT NULL,
	[IsOwned] [bit] NOT NULL,
	[ProjectedVATAmount_Amount] [decimal](16, 2) NULL,
	[ProjectedVATAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[ActualVATAmount_Amount] [decimal](16, 2) NULL,
	[ActualVATAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[CountryId] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[SecurityDeposits]  WITH CHECK ADD  CONSTRAINT [ESecurityDeposit_BillTo] FOREIGN KEY([BillToId])
REFERENCES [dbo].[BillToes] ([Id])
GO
ALTER TABLE [dbo].[SecurityDeposits] CHECK CONSTRAINT [ESecurityDeposit_BillTo]
GO
ALTER TABLE [dbo].[SecurityDeposits]  WITH CHECK ADD  CONSTRAINT [ESecurityDeposit_Contract] FOREIGN KEY([ContractId])
REFERENCES [dbo].[Contracts] ([Id])
GO
ALTER TABLE [dbo].[SecurityDeposits] CHECK CONSTRAINT [ESecurityDeposit_Contract]
GO
ALTER TABLE [dbo].[SecurityDeposits]  WITH CHECK ADD  CONSTRAINT [ESecurityDeposit_CostCenter] FOREIGN KEY([CostCenterId])
REFERENCES [dbo].[CostCenterConfigs] ([Id])
GO
ALTER TABLE [dbo].[SecurityDeposits] CHECK CONSTRAINT [ESecurityDeposit_CostCenter]
GO
ALTER TABLE [dbo].[SecurityDeposits]  WITH CHECK ADD  CONSTRAINT [ESecurityDeposit_Country] FOREIGN KEY([CountryId])
REFERENCES [dbo].[Countries] ([Id])
GO
ALTER TABLE [dbo].[SecurityDeposits] CHECK CONSTRAINT [ESecurityDeposit_Country]
GO
ALTER TABLE [dbo].[SecurityDeposits]  WITH CHECK ADD  CONSTRAINT [ESecurityDeposit_Currency] FOREIGN KEY([CurrencyId])
REFERENCES [dbo].[Currencies] ([Id])
GO
ALTER TABLE [dbo].[SecurityDeposits] CHECK CONSTRAINT [ESecurityDeposit_Currency]
GO
ALTER TABLE [dbo].[SecurityDeposits]  WITH CHECK ADD  CONSTRAINT [ESecurityDeposit_Customer] FOREIGN KEY([CustomerId])
REFERENCES [dbo].[Customers] ([Id])
GO
ALTER TABLE [dbo].[SecurityDeposits] CHECK CONSTRAINT [ESecurityDeposit_Customer]
GO
ALTER TABLE [dbo].[SecurityDeposits]  WITH CHECK ADD  CONSTRAINT [ESecurityDeposit_InstrumentType] FOREIGN KEY([InstrumentTypeId])
REFERENCES [dbo].[InstrumentTypes] ([Id])
GO
ALTER TABLE [dbo].[SecurityDeposits] CHECK CONSTRAINT [ESecurityDeposit_InstrumentType]
GO
ALTER TABLE [dbo].[SecurityDeposits]  WITH CHECK ADD  CONSTRAINT [ESecurityDeposit_LegalEntity] FOREIGN KEY([LegalEntityId])
REFERENCES [dbo].[LegalEntities] ([Id])
GO
ALTER TABLE [dbo].[SecurityDeposits] CHECK CONSTRAINT [ESecurityDeposit_LegalEntity]
GO
ALTER TABLE [dbo].[SecurityDeposits]  WITH CHECK ADD  CONSTRAINT [ESecurityDeposit_LineofBusiness] FOREIGN KEY([LineofBusinessId])
REFERENCES [dbo].[LineofBusinesses] ([Id])
GO
ALTER TABLE [dbo].[SecurityDeposits] CHECK CONSTRAINT [ESecurityDeposit_LineofBusiness]
GO
ALTER TABLE [dbo].[SecurityDeposits]  WITH CHECK ADD  CONSTRAINT [ESecurityDeposit_Location] FOREIGN KEY([LocationId])
REFERENCES [dbo].[Locations] ([Id])
GO
ALTER TABLE [dbo].[SecurityDeposits] CHECK CONSTRAINT [ESecurityDeposit_Location]
GO
ALTER TABLE [dbo].[SecurityDeposits]  WITH CHECK ADD  CONSTRAINT [ESecurityDeposit_ReceiptGLTemplate] FOREIGN KEY([ReceiptGLTemplateId])
REFERENCES [dbo].[GLTemplates] ([Id])
GO
ALTER TABLE [dbo].[SecurityDeposits] CHECK CONSTRAINT [ESecurityDeposit_ReceiptGLTemplate]
GO
ALTER TABLE [dbo].[SecurityDeposits]  WITH CHECK ADD  CONSTRAINT [ESecurityDeposit_Receivable] FOREIGN KEY([ReceivableId])
REFERENCES [dbo].[Receivables] ([Id])
GO
ALTER TABLE [dbo].[SecurityDeposits] CHECK CONSTRAINT [ESecurityDeposit_Receivable]
GO
ALTER TABLE [dbo].[SecurityDeposits]  WITH CHECK ADD  CONSTRAINT [ESecurityDeposit_ReceivableCode] FOREIGN KEY([ReceivableCodeId])
REFERENCES [dbo].[ReceivableCodes] ([Id])
GO
ALTER TABLE [dbo].[SecurityDeposits] CHECK CONSTRAINT [ESecurityDeposit_ReceivableCode]
GO
ALTER TABLE [dbo].[SecurityDeposits]  WITH CHECK ADD  CONSTRAINT [ESecurityDeposit_RemitTo] FOREIGN KEY([RemitToId])
REFERENCES [dbo].[RemitToes] ([Id])
GO
ALTER TABLE [dbo].[SecurityDeposits] CHECK CONSTRAINT [ESecurityDeposit_RemitTo]
GO
