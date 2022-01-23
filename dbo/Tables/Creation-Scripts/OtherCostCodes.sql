SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[OtherCostCodes](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[EntityType] [nvarchar](12) COLLATE Latin1_General_CI_AS NOT NULL,
	[AllocationMethod] [nvarchar](22) COLLATE Latin1_General_CI_AS NOT NULL,
	[Description] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[PayableCodeId] [bigint] NULL,
	[ReceivableCodeId] [bigint] NULL,
	[CostTypeId] [bigint] NULL,
	[BlendedItemCodeId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[IsPrepaidUpfrontTax] [bit] NOT NULL,
	[PortfolioId] [bigint] NOT NULL,
	[PayableWithholdingTaxRate] [decimal](5, 2) NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[OtherCostCodes]  WITH CHECK ADD  CONSTRAINT [EOtherCostCode_BlendedItemCode] FOREIGN KEY([BlendedItemCodeId])
REFERENCES [dbo].[BlendedItemCodes] ([Id])
GO
ALTER TABLE [dbo].[OtherCostCodes] CHECK CONSTRAINT [EOtherCostCode_BlendedItemCode]
GO
ALTER TABLE [dbo].[OtherCostCodes]  WITH CHECK ADD  CONSTRAINT [EOtherCostCode_CostType] FOREIGN KEY([CostTypeId])
REFERENCES [dbo].[CostTypes] ([Id])
GO
ALTER TABLE [dbo].[OtherCostCodes] CHECK CONSTRAINT [EOtherCostCode_CostType]
GO
ALTER TABLE [dbo].[OtherCostCodes]  WITH CHECK ADD  CONSTRAINT [EOtherCostCode_PayableCode] FOREIGN KEY([PayableCodeId])
REFERENCES [dbo].[PayableCodes] ([Id])
GO
ALTER TABLE [dbo].[OtherCostCodes] CHECK CONSTRAINT [EOtherCostCode_PayableCode]
GO
ALTER TABLE [dbo].[OtherCostCodes]  WITH CHECK ADD  CONSTRAINT [EOtherCostCode_Portfolio] FOREIGN KEY([PortfolioId])
REFERENCES [dbo].[Portfolios] ([Id])
GO
ALTER TABLE [dbo].[OtherCostCodes] CHECK CONSTRAINT [EOtherCostCode_Portfolio]
GO
ALTER TABLE [dbo].[OtherCostCodes]  WITH CHECK ADD  CONSTRAINT [EOtherCostCode_ReceivableCode] FOREIGN KEY([ReceivableCodeId])
REFERENCES [dbo].[ReceivableCodes] ([Id])
GO
ALTER TABLE [dbo].[OtherCostCodes] CHECK CONSTRAINT [EOtherCostCode_ReceivableCode]
GO
