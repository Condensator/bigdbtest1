SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ReceivableDetailsWithholdingTaxDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[BasisAmount_Amount] [decimal](16, 2) NOT NULL,
	[BasisAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Tax_Amount] [decimal](16, 2) NOT NULL,
	[Tax_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[Balance_Amount] [decimal](16, 2) NOT NULL,
	[Balance_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[EffectiveBalance_Amount] [decimal](16, 2) NOT NULL,
	[EffectiveBalance_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[ReceivableDetailId] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RowVersion] [timestamp] NOT NULL,
	[ReceivableWithholdingTaxDetailId] [bigint] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ReceivableDetailsWithholdingTaxDetails]  WITH CHECK ADD  CONSTRAINT [EReceivableDetailsWithholdingTaxDetail_ReceivableDetail] FOREIGN KEY([ReceivableDetailId])
REFERENCES [dbo].[ReceivableDetails] ([Id])
GO
ALTER TABLE [dbo].[ReceivableDetailsWithholdingTaxDetails] CHECK CONSTRAINT [EReceivableDetailsWithholdingTaxDetail_ReceivableDetail]
GO
ALTER TABLE [dbo].[ReceivableDetailsWithholdingTaxDetails]  WITH CHECK ADD  CONSTRAINT [EReceivableWithholdingTaxDetail_ReceivableDetailsWithholdingTaxDetails] FOREIGN KEY([ReceivableWithholdingTaxDetailId])
REFERENCES [dbo].[ReceivableWithholdingTaxDetails] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[ReceivableDetailsWithholdingTaxDetails] CHECK CONSTRAINT [EReceivableWithholdingTaxDetail_ReceivableDetailsWithholdingTaxDetails]
GO
