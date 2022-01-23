SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DefaultTaxTypeForReceivableTypes](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[CountryId] [bigint] NOT NULL,
	[TaxTypeId] [bigint] NOT NULL,
	[ReceivableTypeId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[DefaultTaxTypeForReceivableTypes]  WITH CHECK ADD  CONSTRAINT [EDefaultTaxTypeForReceivableTypes_Country] FOREIGN KEY([CountryId])
REFERENCES [dbo].[Countries] ([Id])
GO
ALTER TABLE [dbo].[DefaultTaxTypeForReceivableTypes] CHECK CONSTRAINT [EDefaultTaxTypeForReceivableTypes_Country]
GO
ALTER TABLE [dbo].[DefaultTaxTypeForReceivableTypes]  WITH CHECK ADD  CONSTRAINT [EDefaultTaxTypeForReceivableTypes_TaxType] FOREIGN KEY([TaxTypeId])
REFERENCES [dbo].[TaxTypes] ([Id])
GO
ALTER TABLE [dbo].[DefaultTaxTypeForReceivableTypes] CHECK CONSTRAINT [EDefaultTaxTypeForReceivableTypes_TaxType]
GO
ALTER TABLE [dbo].[DefaultTaxTypeForReceivableTypes]  WITH CHECK ADD  CONSTRAINT [EReceivableType_DefaultTaxTypeForReceivableTypes] FOREIGN KEY([ReceivableTypeId])
REFERENCES [dbo].[ReceivableTypes] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[DefaultTaxTypeForReceivableTypes] CHECK CONSTRAINT [EReceivableType_DefaultTaxTypeForReceivableTypes]
GO
