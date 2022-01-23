SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[OneTimeACHes](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[SettlementDate] [date] NOT NULL,
	[AppliedAmount_Amount] [decimal](16, 2) NOT NULL,
	[AppliedAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[ACHAmount_Amount] [decimal](16, 2) NOT NULL,
	[ACHAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[UnAllocatedAmount_Amount] [decimal](16, 2) NOT NULL,
	[UnAllocatedAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsCreateBankAccount] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[Status] [nvarchar](18) COLLATE Latin1_General_CI_AS NOT NULL,
	[AmountDistributionType] [nvarchar](13) COLLATE Latin1_General_CI_AS NOT NULL,
	[CheckNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[BankAccountId] [bigint] NOT NULL,
	[LineofBusinessId] [bigint] NULL,
	[InstrumentTypeId] [bigint] NULL,
	[CustomerId] [bigint] NOT NULL,
	[LegalEntityId] [bigint] NOT NULL,
	[LegalEntityBankAccountId] [bigint] NOT NULL,
	[CurrencyId] [bigint] NOT NULL,
	[CashTypeId] [bigint] NULL,
	[ReceiptGLTemplateId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[CostCenterId] [bigint] NULL,
	[OneTimeACHRequestId] [bigint] NULL,
	[ApplyByReceivable] [bit] NOT NULL,
	[FileGenerationDate] [date] NULL,
	[IsAutoAllocate] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[OneTimeACHes]  WITH CHECK ADD  CONSTRAINT [EOneTimeACH_BankAccount] FOREIGN KEY([BankAccountId])
REFERENCES [dbo].[BankAccounts] ([Id])
GO
ALTER TABLE [dbo].[OneTimeACHes] CHECK CONSTRAINT [EOneTimeACH_BankAccount]
GO
ALTER TABLE [dbo].[OneTimeACHes]  WITH CHECK ADD  CONSTRAINT [EOneTimeACH_CashType] FOREIGN KEY([CashTypeId])
REFERENCES [dbo].[CashTypes] ([Id])
GO
ALTER TABLE [dbo].[OneTimeACHes] CHECK CONSTRAINT [EOneTimeACH_CashType]
GO
ALTER TABLE [dbo].[OneTimeACHes]  WITH CHECK ADD  CONSTRAINT [EOneTimeACH_CostCenter] FOREIGN KEY([CostCenterId])
REFERENCES [dbo].[CostCenterConfigs] ([Id])
GO
ALTER TABLE [dbo].[OneTimeACHes] CHECK CONSTRAINT [EOneTimeACH_CostCenter]
GO
ALTER TABLE [dbo].[OneTimeACHes]  WITH CHECK ADD  CONSTRAINT [EOneTimeACH_Currency] FOREIGN KEY([CurrencyId])
REFERENCES [dbo].[Currencies] ([Id])
GO
ALTER TABLE [dbo].[OneTimeACHes] CHECK CONSTRAINT [EOneTimeACH_Currency]
GO
ALTER TABLE [dbo].[OneTimeACHes]  WITH CHECK ADD  CONSTRAINT [EOneTimeACH_Customer] FOREIGN KEY([CustomerId])
REFERENCES [dbo].[Customers] ([Id])
GO
ALTER TABLE [dbo].[OneTimeACHes] CHECK CONSTRAINT [EOneTimeACH_Customer]
GO
ALTER TABLE [dbo].[OneTimeACHes]  WITH CHECK ADD  CONSTRAINT [EOneTimeACH_InstrumentType] FOREIGN KEY([InstrumentTypeId])
REFERENCES [dbo].[InstrumentTypes] ([Id])
GO
ALTER TABLE [dbo].[OneTimeACHes] CHECK CONSTRAINT [EOneTimeACH_InstrumentType]
GO
ALTER TABLE [dbo].[OneTimeACHes]  WITH CHECK ADD  CONSTRAINT [EOneTimeACH_LegalEntity] FOREIGN KEY([LegalEntityId])
REFERENCES [dbo].[LegalEntities] ([Id])
GO
ALTER TABLE [dbo].[OneTimeACHes] CHECK CONSTRAINT [EOneTimeACH_LegalEntity]
GO
ALTER TABLE [dbo].[OneTimeACHes]  WITH CHECK ADD  CONSTRAINT [EOneTimeACH_LegalEntityBankAccount] FOREIGN KEY([LegalEntityBankAccountId])
REFERENCES [dbo].[BankAccounts] ([Id])
GO
ALTER TABLE [dbo].[OneTimeACHes] CHECK CONSTRAINT [EOneTimeACH_LegalEntityBankAccount]
GO
ALTER TABLE [dbo].[OneTimeACHes]  WITH CHECK ADD  CONSTRAINT [EOneTimeACH_LineofBusiness] FOREIGN KEY([LineofBusinessId])
REFERENCES [dbo].[LineofBusinesses] ([Id])
GO
ALTER TABLE [dbo].[OneTimeACHes] CHECK CONSTRAINT [EOneTimeACH_LineofBusiness]
GO
ALTER TABLE [dbo].[OneTimeACHes]  WITH CHECK ADD  CONSTRAINT [EOneTimeACH_OneTimeACHRequest] FOREIGN KEY([OneTimeACHRequestId])
REFERENCES [dbo].[OneTimeACHRequests] ([Id])
GO
ALTER TABLE [dbo].[OneTimeACHes] CHECK CONSTRAINT [EOneTimeACH_OneTimeACHRequest]
GO
ALTER TABLE [dbo].[OneTimeACHes]  WITH CHECK ADD  CONSTRAINT [EOneTimeACH_ReceiptGLTemplate] FOREIGN KEY([ReceiptGLTemplateId])
REFERENCES [dbo].[GLTemplates] ([Id])
GO
ALTER TABLE [dbo].[OneTimeACHes] CHECK CONSTRAINT [EOneTimeACH_ReceiptGLTemplate]
GO
