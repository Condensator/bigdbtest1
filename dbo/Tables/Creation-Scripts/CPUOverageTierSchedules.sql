SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CPUOverageTierSchedules](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[StartDate] [date] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[IsActive] [bit] NOT NULL,
	[CPUOverageStructureId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CPUOverageTierSchedules]  WITH CHECK ADD  CONSTRAINT [ECPUOverageStructure_CPUOverageTierSchedules] FOREIGN KEY([CPUOverageStructureId])
REFERENCES [dbo].[CPUOverageStructures] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CPUOverageTierSchedules] CHECK CONSTRAINT [ECPUOverageStructure_CPUOverageTierSchedules]
GO
