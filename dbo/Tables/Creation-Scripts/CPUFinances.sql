SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CPUFinances](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[CommencementDate] [date] NOT NULL,
	[DueDay] [int] NOT NULL,
	[ReadDay] [int] NULL,
	[BasePaymentFrequency] [nvarchar](13) COLLATE Latin1_General_CI_AS NULL,
	[IsAdvanceBilling] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RowVersion] [timestamp] NOT NULL,
	[LegalEntityId] [bigint] NOT NULL,
	[CustomerId] [bigint] NOT NULL,
	[CurrencyId] [bigint] NOT NULL,
	[PayoffDate] [date] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CPUFinances]  WITH CHECK ADD  CONSTRAINT [ECPUFinance_Currency] FOREIGN KEY([CurrencyId])
REFERENCES [dbo].[Currencies] ([Id])
GO
ALTER TABLE [dbo].[CPUFinances] CHECK CONSTRAINT [ECPUFinance_Currency]
GO
ALTER TABLE [dbo].[CPUFinances]  WITH CHECK ADD  CONSTRAINT [ECPUFinance_Customer] FOREIGN KEY([CustomerId])
REFERENCES [dbo].[Customers] ([Id])
GO
ALTER TABLE [dbo].[CPUFinances] CHECK CONSTRAINT [ECPUFinance_Customer]
GO
ALTER TABLE [dbo].[CPUFinances]  WITH CHECK ADD  CONSTRAINT [ECPUFinance_LegalEntity] FOREIGN KEY([LegalEntityId])
REFERENCES [dbo].[LegalEntities] ([Id])
GO
ALTER TABLE [dbo].[CPUFinances] CHECK CONSTRAINT [ECPUFinance_LegalEntity]
GO
