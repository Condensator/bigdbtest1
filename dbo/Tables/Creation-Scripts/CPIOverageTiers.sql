SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CPIOverageTiers](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[BeginOverageUnit] [int] NOT NULL,
	[OverageRate] [decimal](8, 4) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[CPIScheduleId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[LastOverageRateUsed] [decimal](8, 4) NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CPIOverageTiers]  WITH CHECK ADD  CONSTRAINT [ECPISchedule_CPIOverageTiers] FOREIGN KEY([CPIScheduleId])
REFERENCES [dbo].[CPISchedules] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CPIOverageTiers] CHECK CONSTRAINT [ECPISchedule_CPIOverageTiers]
GO
