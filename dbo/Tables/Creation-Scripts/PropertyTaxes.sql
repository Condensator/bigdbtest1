SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PropertyTaxes](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[ReportingYear] [decimal](4, 0) NOT NULL,
	[LienDate] [date] NULL,
	[BillNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[TaxDistrict] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[CollectorTitle] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[PropertyTaxRate] [decimal](8, 4) NOT NULL,
	[PropertyTaxAmount_Amount] [decimal](16, 2) NOT NULL,
	[PropertyTaxAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[DueDate] [date] NOT NULL,
	[PostDate] [date] NOT NULL,
	[DisbursementBatchID] [int] NULL,
	[ReversalPostDate] [date] NULL,
	[InvoiceAmendmentType] [nvarchar](20) COLLATE Latin1_General_CI_AS NOT NULL,
	[InvoiceComment] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[NumberofInstallments] [int] NULL,
	[InstallmentNumber] [int] NULL,
	[IsActive] [bit] NOT NULL,
	[IsManuallyAssessed] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ContractId] [bigint] NOT NULL,
	[StateId] [bigint] NULL,
	[RemitToId] [bigint] NULL,
	[ReceivableCodeId] [bigint] NOT NULL,
	[ReceivableCodeForAdminFeeId] [bigint] NULL,
	[PropTaxReceivableId] [bigint] NULL,
	[ReceivableForAdminFeeId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[PropertyTaxes]  WITH CHECK ADD  CONSTRAINT [EPropertyTax_Contract] FOREIGN KEY([ContractId])
REFERENCES [dbo].[Contracts] ([Id])
GO
ALTER TABLE [dbo].[PropertyTaxes] CHECK CONSTRAINT [EPropertyTax_Contract]
GO
ALTER TABLE [dbo].[PropertyTaxes]  WITH CHECK ADD  CONSTRAINT [EPropertyTax_PropTaxReceivable] FOREIGN KEY([PropTaxReceivableId])
REFERENCES [dbo].[Receivables] ([Id])
GO
ALTER TABLE [dbo].[PropertyTaxes] CHECK CONSTRAINT [EPropertyTax_PropTaxReceivable]
GO
ALTER TABLE [dbo].[PropertyTaxes]  WITH CHECK ADD  CONSTRAINT [EPropertyTax_ReceivableCode] FOREIGN KEY([ReceivableCodeId])
REFERENCES [dbo].[ReceivableCodes] ([Id])
GO
ALTER TABLE [dbo].[PropertyTaxes] CHECK CONSTRAINT [EPropertyTax_ReceivableCode]
GO
ALTER TABLE [dbo].[PropertyTaxes]  WITH CHECK ADD  CONSTRAINT [EPropertyTax_ReceivableCodeForAdminFee] FOREIGN KEY([ReceivableCodeForAdminFeeId])
REFERENCES [dbo].[ReceivableCodes] ([Id])
GO
ALTER TABLE [dbo].[PropertyTaxes] CHECK CONSTRAINT [EPropertyTax_ReceivableCodeForAdminFee]
GO
ALTER TABLE [dbo].[PropertyTaxes]  WITH CHECK ADD  CONSTRAINT [EPropertyTax_ReceivableForAdminFee] FOREIGN KEY([ReceivableForAdminFeeId])
REFERENCES [dbo].[Receivables] ([Id])
GO
ALTER TABLE [dbo].[PropertyTaxes] CHECK CONSTRAINT [EPropertyTax_ReceivableForAdminFee]
GO
ALTER TABLE [dbo].[PropertyTaxes]  WITH CHECK ADD  CONSTRAINT [EPropertyTax_RemitTo] FOREIGN KEY([RemitToId])
REFERENCES [dbo].[RemitToes] ([Id])
GO
ALTER TABLE [dbo].[PropertyTaxes] CHECK CONSTRAINT [EPropertyTax_RemitTo]
GO
ALTER TABLE [dbo].[PropertyTaxes]  WITH CHECK ADD  CONSTRAINT [EPropertyTax_State] FOREIGN KEY([StateId])
REFERENCES [dbo].[States] ([Id])
GO
ALTER TABLE [dbo].[PropertyTaxes] CHECK CONSTRAINT [EPropertyTax_State]
GO
