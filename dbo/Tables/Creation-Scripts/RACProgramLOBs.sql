SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[RACProgramLOBs](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[AssignmentDate] [date] NULL,
	[UnAssignmentDate] [date] NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[LineofBusinessId] [bigint] NULL,
	[RACProgramId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[RACProgramLOBs]  WITH CHECK ADD  CONSTRAINT [ERACProgram_RACProgramLOBs] FOREIGN KEY([RACProgramId])
REFERENCES [dbo].[RACPrograms] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[RACProgramLOBs] CHECK CONSTRAINT [ERACProgram_RACProgramLOBs]
GO
ALTER TABLE [dbo].[RACProgramLOBs]  WITH CHECK ADD  CONSTRAINT [ERACProgramLOB_LineofBusiness] FOREIGN KEY([LineofBusinessId])
REFERENCES [dbo].[LineofBusinesses] ([Id])
GO
ALTER TABLE [dbo].[RACProgramLOBs] CHECK CONSTRAINT [ERACProgramLOB_LineofBusiness]
GO
