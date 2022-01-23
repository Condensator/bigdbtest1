SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CPUOverageTiers](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[BeginUnit] [int] NOT NULL,
	[Rate] [decimal](14, 9) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CPUOverageStructureId] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RowVersion] [timestamp] NOT NULL,
	[IsCreatedFromBooking] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CPUOverageTiers]  WITH CHECK ADD  CONSTRAINT [ECPUOverageStructure_CPUOverageTiers] FOREIGN KEY([CPUOverageStructureId])
REFERENCES [dbo].[CPUOverageStructures] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CPUOverageTiers] CHECK CONSTRAINT [ECPUOverageStructure_CPUOverageTiers]
GO
