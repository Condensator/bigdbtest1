SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AccountsPayablePayments](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Status] [nvarchar](23) COLLATE Latin1_General_CI_AS NULL,
	[PaymentDate] [date] NULL,
	[PostDate] [date] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RowVersion] [timestamp] NOT NULL,
	[IsIntercompany] [bit] NOT NULL,
	[LegalEntityId] [bigint] NULL,
	[GLTemplateId] [bigint] NULL,
	[BusinessUnitId] [bigint] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[AccountsPayablePayments]  WITH CHECK ADD  CONSTRAINT [EAccountsPayablePayment_BusinessUnit] FOREIGN KEY([BusinessUnitId])
REFERENCES [dbo].[BusinessUnits] ([Id])
GO
ALTER TABLE [dbo].[AccountsPayablePayments] CHECK CONSTRAINT [EAccountsPayablePayment_BusinessUnit]
GO
ALTER TABLE [dbo].[AccountsPayablePayments]  WITH CHECK ADD  CONSTRAINT [EAccountsPayablePayment_GLTemplate] FOREIGN KEY([GLTemplateId])
REFERENCES [dbo].[GLTemplates] ([Id])
GO
ALTER TABLE [dbo].[AccountsPayablePayments] CHECK CONSTRAINT [EAccountsPayablePayment_GLTemplate]
GO
ALTER TABLE [dbo].[AccountsPayablePayments]  WITH CHECK ADD  CONSTRAINT [EAccountsPayablePayment_LegalEntity] FOREIGN KEY([LegalEntityId])
REFERENCES [dbo].[LegalEntities] ([Id])
GO
ALTER TABLE [dbo].[AccountsPayablePayments] CHECK CONSTRAINT [EAccountsPayablePayment_LegalEntity]
GO
