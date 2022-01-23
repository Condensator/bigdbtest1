SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DisbursementRequests](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[PostDate] [date] NULL,
	[Status] [nvarchar](25) COLLATE Latin1_General_CI_AS NOT NULL,
	[Comment] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[ImportInvoice] [bit] NOT NULL,
	[ApplyByPayable] [bit] NOT NULL,
	[PaymentDate] [date] NULL,
	[OriginationType] [nvarchar](14) COLLATE Latin1_General_CI_AS NULL,
	[ContractSequenceNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[IsScheduledFunding] [bit] NOT NULL,
	[ReceiptId] [bigint] NULL,
	[Type] [nvarchar](11) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[PayeeId] [bigint] NOT NULL,
	[LegalEntityId] [bigint] NOT NULL,
	[CurrencyId] [bigint] NULL,
	[ContractCurrencyId] [bigint] NULL,
	[RejectionReasonId] [bigint] NULL,
	[APGLTemplateId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[IsFromPI] [bit] NOT NULL,
	[BillToId] [bigint] NULL,
	[ReceivableCodeId] [bigint] NULL,
	[LocationId] [bigint] NULL,
	[LineOfBusinessId] [bigint] NULL,
	[CostCenterId] [bigint] NULL,
	[InstrumentTypeId] [bigint] NULL,
	[RemitToId] [bigint] NULL,
	[ReceivableDueDate] [date] NULL,
	[ClearingOption] [nvarchar](16) COLLATE Latin1_General_CI_AS NULL,
	[SundryId] [bigint] NULL,
	[BranchId] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[DisbursementRequests]  WITH CHECK ADD  CONSTRAINT [EDisbursementRequest_APGLTemplate] FOREIGN KEY([APGLTemplateId])
REFERENCES [dbo].[GLTemplates] ([Id])
GO
ALTER TABLE [dbo].[DisbursementRequests] CHECK CONSTRAINT [EDisbursementRequest_APGLTemplate]
GO
ALTER TABLE [dbo].[DisbursementRequests]  WITH CHECK ADD  CONSTRAINT [EDisbursementRequest_BillTo] FOREIGN KEY([BillToId])
REFERENCES [dbo].[BillToes] ([Id])
GO
ALTER TABLE [dbo].[DisbursementRequests] CHECK CONSTRAINT [EDisbursementRequest_BillTo]
GO
ALTER TABLE [dbo].[DisbursementRequests]  WITH CHECK ADD  CONSTRAINT [EDisbursementRequest_Branch] FOREIGN KEY([BranchId])
REFERENCES [dbo].[Branches] ([Id])
GO
ALTER TABLE [dbo].[DisbursementRequests] CHECK CONSTRAINT [EDisbursementRequest_Branch]
GO
ALTER TABLE [dbo].[DisbursementRequests]  WITH CHECK ADD  CONSTRAINT [EDisbursementRequest_ContractCurrency] FOREIGN KEY([ContractCurrencyId])
REFERENCES [dbo].[Currencies] ([Id])
GO
ALTER TABLE [dbo].[DisbursementRequests] CHECK CONSTRAINT [EDisbursementRequest_ContractCurrency]
GO
ALTER TABLE [dbo].[DisbursementRequests]  WITH CHECK ADD  CONSTRAINT [EDisbursementRequest_CostCenter] FOREIGN KEY([CostCenterId])
REFERENCES [dbo].[CostCenterConfigs] ([Id])
GO
ALTER TABLE [dbo].[DisbursementRequests] CHECK CONSTRAINT [EDisbursementRequest_CostCenter]
GO
ALTER TABLE [dbo].[DisbursementRequests]  WITH CHECK ADD  CONSTRAINT [EDisbursementRequest_Currency] FOREIGN KEY([CurrencyId])
REFERENCES [dbo].[Currencies] ([Id])
GO
ALTER TABLE [dbo].[DisbursementRequests] CHECK CONSTRAINT [EDisbursementRequest_Currency]
GO
ALTER TABLE [dbo].[DisbursementRequests]  WITH CHECK ADD  CONSTRAINT [EDisbursementRequest_InstrumentType] FOREIGN KEY([InstrumentTypeId])
REFERENCES [dbo].[InstrumentTypes] ([Id])
GO
ALTER TABLE [dbo].[DisbursementRequests] CHECK CONSTRAINT [EDisbursementRequest_InstrumentType]
GO
ALTER TABLE [dbo].[DisbursementRequests]  WITH CHECK ADD  CONSTRAINT [EDisbursementRequest_LegalEntity] FOREIGN KEY([LegalEntityId])
REFERENCES [dbo].[LegalEntities] ([Id])
GO
ALTER TABLE [dbo].[DisbursementRequests] CHECK CONSTRAINT [EDisbursementRequest_LegalEntity]
GO
ALTER TABLE [dbo].[DisbursementRequests]  WITH CHECK ADD  CONSTRAINT [EDisbursementRequest_LineofBusiness] FOREIGN KEY([LineOfBusinessId])
REFERENCES [dbo].[LineofBusinesses] ([Id])
GO
ALTER TABLE [dbo].[DisbursementRequests] CHECK CONSTRAINT [EDisbursementRequest_LineofBusiness]
GO
ALTER TABLE [dbo].[DisbursementRequests]  WITH CHECK ADD  CONSTRAINT [EDisbursementRequest_Location] FOREIGN KEY([LocationId])
REFERENCES [dbo].[Locations] ([Id])
GO
ALTER TABLE [dbo].[DisbursementRequests] CHECK CONSTRAINT [EDisbursementRequest_Location]
GO
ALTER TABLE [dbo].[DisbursementRequests]  WITH CHECK ADD  CONSTRAINT [EDisbursementRequest_Payee] FOREIGN KEY([PayeeId])
REFERENCES [dbo].[Vendors] ([Id])
GO
ALTER TABLE [dbo].[DisbursementRequests] CHECK CONSTRAINT [EDisbursementRequest_Payee]
GO
ALTER TABLE [dbo].[DisbursementRequests]  WITH CHECK ADD  CONSTRAINT [EDisbursementRequest_Receipt] FOREIGN KEY([ReceiptId])
REFERENCES [dbo].[Receipts] ([Id])
GO
ALTER TABLE [dbo].[DisbursementRequests] CHECK CONSTRAINT [EDisbursementRequest_Receipt]
GO
ALTER TABLE [dbo].[DisbursementRequests]  WITH CHECK ADD  CONSTRAINT [EDisbursementRequest_ReceivableCode] FOREIGN KEY([ReceivableCodeId])
REFERENCES [dbo].[ReceivableCodes] ([Id])
GO
ALTER TABLE [dbo].[DisbursementRequests] CHECK CONSTRAINT [EDisbursementRequest_ReceivableCode]
GO
ALTER TABLE [dbo].[DisbursementRequests]  WITH CHECK ADD  CONSTRAINT [EDisbursementRequest_RejectionReason] FOREIGN KEY([RejectionReasonId])
REFERENCES [dbo].[DRRejectionReasonConfigs] ([Id])
GO
ALTER TABLE [dbo].[DisbursementRequests] CHECK CONSTRAINT [EDisbursementRequest_RejectionReason]
GO
ALTER TABLE [dbo].[DisbursementRequests]  WITH CHECK ADD  CONSTRAINT [EDisbursementRequest_RemitTo] FOREIGN KEY([RemitToId])
REFERENCES [dbo].[RemitToes] ([Id])
GO
ALTER TABLE [dbo].[DisbursementRequests] CHECK CONSTRAINT [EDisbursementRequest_RemitTo]
GO
ALTER TABLE [dbo].[DisbursementRequests]  WITH CHECK ADD  CONSTRAINT [EDisbursementRequest_Sundry] FOREIGN KEY([SundryId])
REFERENCES [dbo].[Sundries] ([Id])
GO
ALTER TABLE [dbo].[DisbursementRequests] CHECK CONSTRAINT [EDisbursementRequest_Sundry]
GO
