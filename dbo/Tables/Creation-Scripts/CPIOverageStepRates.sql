SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CPIOverageStepRates](
	[TierRate] [decimal](8, 4) NULL,
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[StepPeriod] [int] NULL,
	[CPIReceivableId] [bigint] NULL,
	[CPIOverageTierId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CPIOverageStepRates]  WITH CHECK ADD  CONSTRAINT [ECPIOverageStepRate_CPIOverageTier] FOREIGN KEY([CPIOverageTierId])
REFERENCES [dbo].[CPIOverageTiers] ([Id])
GO
ALTER TABLE [dbo].[CPIOverageStepRates] CHECK CONSTRAINT [ECPIOverageStepRate_CPIOverageTier]
GO
ALTER TABLE [dbo].[CPIOverageStepRates]  WITH CHECK ADD  CONSTRAINT [ECPIOverageStepRate_CPIReceivable] FOREIGN KEY([CPIReceivableId])
REFERENCES [dbo].[CPIReceivables] ([Id])
GO
ALTER TABLE [dbo].[CPIOverageStepRates] CHECK CONSTRAINT [ECPIOverageStepRate_CPIReceivable]
GO
