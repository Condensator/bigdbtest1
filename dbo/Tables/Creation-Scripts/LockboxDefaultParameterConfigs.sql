SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LockboxDefaultParameterConfigs](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[LegalEntityId] [bigint] NULL,
	[CostCenterId] [bigint] NULL,
	[CurrencyId] [bigint] NULL,
	[LineOfBusinessId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[CashTypeId] [bigint] NULL,
	[InstrumentTypeId] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[LockboxDefaultParameterConfigs]  WITH CHECK ADD  CONSTRAINT [ELockboxDefaultParameterConfig_CashType] FOREIGN KEY([CashTypeId])
REFERENCES [dbo].[CashTypes] ([Id])
GO
ALTER TABLE [dbo].[LockboxDefaultParameterConfigs] CHECK CONSTRAINT [ELockboxDefaultParameterConfig_CashType]
GO
ALTER TABLE [dbo].[LockboxDefaultParameterConfigs]  WITH CHECK ADD  CONSTRAINT [ELockboxDefaultParameterConfig_CostCenter] FOREIGN KEY([CostCenterId])
REFERENCES [dbo].[CostCenterConfigs] ([Id])
GO
ALTER TABLE [dbo].[LockboxDefaultParameterConfigs] CHECK CONSTRAINT [ELockboxDefaultParameterConfig_CostCenter]
GO
ALTER TABLE [dbo].[LockboxDefaultParameterConfigs]  WITH CHECK ADD  CONSTRAINT [ELockboxDefaultParameterConfig_Currency] FOREIGN KEY([CurrencyId])
REFERENCES [dbo].[Currencies] ([Id])
GO
ALTER TABLE [dbo].[LockboxDefaultParameterConfigs] CHECK CONSTRAINT [ELockboxDefaultParameterConfig_Currency]
GO
ALTER TABLE [dbo].[LockboxDefaultParameterConfigs]  WITH CHECK ADD  CONSTRAINT [ELockboxDefaultParameterConfig_InstrumentType] FOREIGN KEY([InstrumentTypeId])
REFERENCES [dbo].[InstrumentTypes] ([Id])
GO
ALTER TABLE [dbo].[LockboxDefaultParameterConfigs] CHECK CONSTRAINT [ELockboxDefaultParameterConfig_InstrumentType]
GO
ALTER TABLE [dbo].[LockboxDefaultParameterConfigs]  WITH CHECK ADD  CONSTRAINT [ELockboxDefaultParameterConfig_LegalEntity] FOREIGN KEY([LegalEntityId])
REFERENCES [dbo].[LegalEntities] ([Id])
GO
ALTER TABLE [dbo].[LockboxDefaultParameterConfigs] CHECK CONSTRAINT [ELockboxDefaultParameterConfig_LegalEntity]
GO
ALTER TABLE [dbo].[LockboxDefaultParameterConfigs]  WITH CHECK ADD  CONSTRAINT [ELockboxDefaultParameterConfig_LineOfBusiness] FOREIGN KEY([LineOfBusinessId])
REFERENCES [dbo].[LineofBusinesses] ([Id])
GO
ALTER TABLE [dbo].[LockboxDefaultParameterConfigs] CHECK CONSTRAINT [ELockboxDefaultParameterConfig_LineOfBusiness]
GO
