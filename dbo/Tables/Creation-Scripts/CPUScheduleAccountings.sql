SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CPUScheduleAccountings](
	[Id] [bigint] NOT NULL,
	[BaseFeeReceivableCodeId] [bigint] NULL,
	[OverageFeeReceivableCodeId] [bigint] NULL,
	[BaseFeePayableCodeId] [bigint] NULL,
	[OverageFeePayableCodeId] [bigint] NULL,
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
ALTER TABLE [dbo].[CPUScheduleAccountings]  WITH CHECK ADD  CONSTRAINT [ECPUSchedule_CPUScheduleAccounting] FOREIGN KEY([Id])
REFERENCES [dbo].[CPUSchedules] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CPUScheduleAccountings] CHECK CONSTRAINT [ECPUSchedule_CPUScheduleAccounting]
GO
ALTER TABLE [dbo].[CPUScheduleAccountings]  WITH CHECK ADD  CONSTRAINT [ECPUScheduleAccounting_BaseFeePayableCode] FOREIGN KEY([BaseFeePayableCodeId])
REFERENCES [dbo].[PayableCodes] ([Id])
GO
ALTER TABLE [dbo].[CPUScheduleAccountings] CHECK CONSTRAINT [ECPUScheduleAccounting_BaseFeePayableCode]
GO
ALTER TABLE [dbo].[CPUScheduleAccountings]  WITH CHECK ADD  CONSTRAINT [ECPUScheduleAccounting_BaseFeeReceivableCode] FOREIGN KEY([BaseFeeReceivableCodeId])
REFERENCES [dbo].[ReceivableCodes] ([Id])
GO
ALTER TABLE [dbo].[CPUScheduleAccountings] CHECK CONSTRAINT [ECPUScheduleAccounting_BaseFeeReceivableCode]
GO
ALTER TABLE [dbo].[CPUScheduleAccountings]  WITH CHECK ADD  CONSTRAINT [ECPUScheduleAccounting_OverageFeePayableCode] FOREIGN KEY([OverageFeePayableCodeId])
REFERENCES [dbo].[PayableCodes] ([Id])
GO
ALTER TABLE [dbo].[CPUScheduleAccountings] CHECK CONSTRAINT [ECPUScheduleAccounting_OverageFeePayableCode]
GO
ALTER TABLE [dbo].[CPUScheduleAccountings]  WITH CHECK ADD  CONSTRAINT [ECPUScheduleAccounting_OverageFeeReceivableCode] FOREIGN KEY([OverageFeeReceivableCodeId])
REFERENCES [dbo].[ReceivableCodes] ([Id])
GO
ALTER TABLE [dbo].[CPUScheduleAccountings] CHECK CONSTRAINT [ECPUScheduleAccounting_OverageFeeReceivableCode]
GO
