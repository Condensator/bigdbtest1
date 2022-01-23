SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ContractFloatRates](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[EffectiveDate] [date] NOT NULL,
	[IsProcessed] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[FloatRateId] [bigint] NOT NULL,
	[ContractId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[IsProcessedByPaymentSchedule] [bit] NOT NULL,
	[IsAutoRestructureProcessed] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ContractFloatRates]  WITH CHECK ADD  CONSTRAINT [EContract_ContractFloatRates] FOREIGN KEY([ContractId])
REFERENCES [dbo].[Contracts] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[ContractFloatRates] CHECK CONSTRAINT [EContract_ContractFloatRates]
GO
ALTER TABLE [dbo].[ContractFloatRates]  WITH CHECK ADD  CONSTRAINT [EContractFloatRate_FloatRate] FOREIGN KEY([FloatRateId])
REFERENCES [dbo].[FloatRateIndexes] ([Id])
GO
ALTER TABLE [dbo].[ContractFloatRates] CHECK CONSTRAINT [EContractFloatRate_FloatRate]
GO
