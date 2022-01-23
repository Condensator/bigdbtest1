SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CPISchedules](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Number] [int] NOT NULL,
	[BeginDate] [date] NOT NULL,
	[NextStartDate] [date] NULL,
	[ApplyByAsset] [bit] NOT NULL,
	[BaseRateCalculated] [bit] NOT NULL,
	[BaseRate] [decimal](8, 4) NOT NULL,
	[BaseAllowance] [int] NOT NULL,
	[BaseAmount_Amount] [decimal](16, 2) NOT NULL,
	[BaseAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[AdminFee_Amount] [decimal](16, 2) NULL,
	[AdminFee_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[InvoiceAmendmentType] [nvarchar](20) COLLATE Latin1_General_CI_AS NULL,
	[OverageTier] [nvarchar](9) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[BaseChargeGeneratedTillDate] [date] NULL,
	[OverageChargeGeneratedTillDate] [date] NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[MeterTypeId] [bigint] NOT NULL,
	[CPIContractId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[TaxLocationId] [bigint] NULL,
	[BaseStepPayments] [bit] NOT NULL,
	[OverageStepPayments] [bit] NOT NULL,
	[BaseStepPercentage] [decimal](5, 2) NULL,
	[OverageStepPercentage] [decimal](5, 2) NULL,
	[BaseStepPeriod] [int] NULL,
	[OverageStepPeriod] [int] NULL,
	[BaseStepPaymentEffectiveDate] [date] NULL,
	[OverageStepPaymentEffectiveDate] [date] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CPISchedules]  WITH CHECK ADD  CONSTRAINT [ECPIContract_CPISchedules] FOREIGN KEY([CPIContractId])
REFERENCES [dbo].[CPIContracts] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CPISchedules] CHECK CONSTRAINT [ECPIContract_CPISchedules]
GO
ALTER TABLE [dbo].[CPISchedules]  WITH CHECK ADD  CONSTRAINT [ECPISchedule_MeterType] FOREIGN KEY([MeterTypeId])
REFERENCES [dbo].[AssetMeterTypes] ([Id])
GO
ALTER TABLE [dbo].[CPISchedules] CHECK CONSTRAINT [ECPISchedule_MeterType]
GO
ALTER TABLE [dbo].[CPISchedules]  WITH CHECK ADD  CONSTRAINT [ECPISchedule_TaxLocation] FOREIGN KEY([TaxLocationId])
REFERENCES [dbo].[Locations] ([Id])
GO
ALTER TABLE [dbo].[CPISchedules] CHECK CONSTRAINT [ECPISchedule_TaxLocation]
GO
