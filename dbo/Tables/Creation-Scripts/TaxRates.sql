SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TaxRates](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[TaxRateHeaderId] [bigint] NOT NULL,
	[TaxImpositionTypeId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[TaxRates]  WITH CHECK ADD  CONSTRAINT [ETaxRate_TaxImpositionType] FOREIGN KEY([TaxImpositionTypeId])
REFERENCES [dbo].[TaxImpositionTypes] ([Id])
GO
ALTER TABLE [dbo].[TaxRates] CHECK CONSTRAINT [ETaxRate_TaxImpositionType]
GO
ALTER TABLE [dbo].[TaxRates]  WITH CHECK ADD  CONSTRAINT [ETaxRateHeader_TaxRates] FOREIGN KEY([TaxRateHeaderId])
REFERENCES [dbo].[TaxRateHeaders] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[TaxRates] CHECK CONSTRAINT [ETaxRateHeader_TaxRates]
GO
