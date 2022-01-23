SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TaxCodeRates](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Rate] [decimal](10, 6) NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[EffectiveDate] [date] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[TaxTypeId] [bigint] NOT NULL,
	[TaxCodeId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[TaxCodeRates]  WITH CHECK ADD  CONSTRAINT [ETaxCode_TaxCodeRates] FOREIGN KEY([TaxCodeId])
REFERENCES [dbo].[TaxCodes] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[TaxCodeRates] CHECK CONSTRAINT [ETaxCode_TaxCodeRates]
GO
ALTER TABLE [dbo].[TaxCodeRates]  WITH CHECK ADD  CONSTRAINT [ETaxCodeRate_TaxType] FOREIGN KEY([TaxTypeId])
REFERENCES [dbo].[TaxTypes] ([Id])
GO
ALTER TABLE [dbo].[TaxCodeRates] CHECK CONSTRAINT [ETaxCodeRate_TaxType]
GO
