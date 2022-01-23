SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TaxDepRateDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[YearNumber] [int] NOT NULL,
	[PeriodNumber] [int] NOT NULL,
	[DepreciationPercent] [decimal](6, 3) NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[TaxDepRateId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[TaxDepRateDetails]  WITH CHECK ADD  CONSTRAINT [ETaxDepRate_TaxDepRateDetails] FOREIGN KEY([TaxDepRateId])
REFERENCES [dbo].[TaxDepRates] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[TaxDepRateDetails] CHECK CONSTRAINT [ETaxDepRate_TaxDepRateDetails]
GO
