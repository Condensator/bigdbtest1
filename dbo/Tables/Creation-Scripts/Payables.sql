SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Payables](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[EntityType] [nvarchar](4) COLLATE Latin1_General_CI_AS NOT NULL,
	[EntityId] [bigint] NOT NULL,
	[Amount_Amount] [decimal](16, 2) NOT NULL,
	[Amount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Balance_Amount] [decimal](16, 2) NOT NULL,
	[Balance_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[DueDate] [date] NOT NULL,
	[Status] [nvarchar](17) COLLATE Latin1_General_CI_AS NOT NULL,
	[SourceTable] [nvarchar](24) COLLATE Latin1_General_CI_AS NOT NULL,
	[SourceId] [bigint] NOT NULL,
	[InternalComment] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[IsGLPosted] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[CurrencyId] [bigint] NOT NULL,
	[PayableCodeId] [bigint] NOT NULL,
	[LegalEntityId] [bigint] NOT NULL,
	[PayeeId] [bigint] NOT NULL,
	[RemitToId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[TaxPortion_Amount] [decimal](16, 2) NOT NULL,
	[TaxPortion_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[AdjustmentBasisPayableId] [bigint] NULL,
	[CreationSourceTable] [nvarchar](5) COLLATE Latin1_General_CI_AS NULL,
	[CreationSourceId] [bigint] NULL,
	[WithholdingTaxRate] [decimal](5, 2) NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[Payables]  WITH CHECK ADD  CONSTRAINT [EPayable_AdjustmentBasisPayable] FOREIGN KEY([AdjustmentBasisPayableId])
REFERENCES [dbo].[Payables] ([Id])
GO
ALTER TABLE [dbo].[Payables] CHECK CONSTRAINT [EPayable_AdjustmentBasisPayable]
GO
ALTER TABLE [dbo].[Payables]  WITH CHECK ADD  CONSTRAINT [EPayable_Currency] FOREIGN KEY([CurrencyId])
REFERENCES [dbo].[Currencies] ([Id])
GO
ALTER TABLE [dbo].[Payables] CHECK CONSTRAINT [EPayable_Currency]
GO
ALTER TABLE [dbo].[Payables]  WITH CHECK ADD  CONSTRAINT [EPayable_LegalEntity] FOREIGN KEY([LegalEntityId])
REFERENCES [dbo].[LegalEntities] ([Id])
GO
ALTER TABLE [dbo].[Payables] CHECK CONSTRAINT [EPayable_LegalEntity]
GO
ALTER TABLE [dbo].[Payables]  WITH CHECK ADD  CONSTRAINT [EPayable_PayableCode] FOREIGN KEY([PayableCodeId])
REFERENCES [dbo].[PayableCodes] ([Id])
GO
ALTER TABLE [dbo].[Payables] CHECK CONSTRAINT [EPayable_PayableCode]
GO
ALTER TABLE [dbo].[Payables]  WITH CHECK ADD  CONSTRAINT [EPayable_Payee] FOREIGN KEY([PayeeId])
REFERENCES [dbo].[Vendors] ([Id])
GO
ALTER TABLE [dbo].[Payables] CHECK CONSTRAINT [EPayable_Payee]
GO
ALTER TABLE [dbo].[Payables]  WITH CHECK ADD  CONSTRAINT [EPayable_RemitTo] FOREIGN KEY([RemitToId])
REFERENCES [dbo].[RemitToes] ([Id])
GO
ALTER TABLE [dbo].[Payables] CHECK CONSTRAINT [EPayable_RemitTo]
GO
