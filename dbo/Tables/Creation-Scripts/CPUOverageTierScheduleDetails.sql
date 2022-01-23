SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CPUOverageTierScheduleDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[BeginOverageUnit] [int] NULL,
	[OverageRate] [decimal](14, 9) NULL,
	[IsActive] [bit] NOT NULL,
	[CPUOverageTierScheduleId] [bigint] NOT NULL,
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
ALTER TABLE [dbo].[CPUOverageTierScheduleDetails]  WITH CHECK ADD  CONSTRAINT [ECPUOverageTierSchedule_CPUOverageTierScheduleDetails] FOREIGN KEY([CPUOverageTierScheduleId])
REFERENCES [dbo].[CPUOverageTierSchedules] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CPUOverageTierScheduleDetails] CHECK CONSTRAINT [ECPUOverageTierSchedule_CPUOverageTierScheduleDetails]
GO
