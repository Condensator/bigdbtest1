SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[WithholdingTaxCodeDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[TaxRate] [decimal](5, 2) NOT NULL,
	[EffectiveDate] [date] NOT NULL,
	[WithholdingTaxCodeId] [bigint] NOT NULL,
	[IsActive] [bit] NOT NULL,
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
ALTER TABLE [dbo].[WithholdingTaxCodeDetails]  WITH CHECK ADD  CONSTRAINT [EWithholdingTaxCode_WithholdingTaxCodeDetails] FOREIGN KEY([WithholdingTaxCodeId])
REFERENCES [dbo].[WithholdingTaxCodes] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[WithholdingTaxCodeDetails] CHECK CONSTRAINT [EWithholdingTaxCode_WithholdingTaxCodeDetails]
GO
