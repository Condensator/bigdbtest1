SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ReceivableWithholdingTaxDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[TaxRate] [decimal](5, 2) NOT NULL,
	[BasisAmount_Amount] [decimal](16, 2) NOT NULL,
	[BasisAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Tax_Amount] [decimal](16, 2) NOT NULL,
	[Tax_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Balance_Amount] [decimal](16, 2) NOT NULL,
	[Balance_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[EffectiveBalance_Amount] [decimal](16, 2) NOT NULL,
	[EffectiveBalance_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[ReceivableId] [bigint] NOT NULL,
	[WithholdingTaxCodeDetailId] [bigint] NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ReceivableWithholdingTaxDetails]  WITH CHECK ADD  CONSTRAINT [EReceivableWithholdingTaxDetail_Receivable] FOREIGN KEY([ReceivableId])
REFERENCES [dbo].[Receivables] ([Id])
GO
ALTER TABLE [dbo].[ReceivableWithholdingTaxDetails] CHECK CONSTRAINT [EReceivableWithholdingTaxDetail_Receivable]
GO
ALTER TABLE [dbo].[ReceivableWithholdingTaxDetails]  WITH CHECK ADD  CONSTRAINT [EReceivableWithholdingTaxDetail_WithholdingTaxCodeDetail] FOREIGN KEY([WithholdingTaxCodeDetailId])
REFERENCES [dbo].[WithholdingTaxCodeDetails] ([Id])
GO
ALTER TABLE [dbo].[ReceivableWithholdingTaxDetails] CHECK CONSTRAINT [EReceivableWithholdingTaxDetail_WithholdingTaxCodeDetail]
GO
