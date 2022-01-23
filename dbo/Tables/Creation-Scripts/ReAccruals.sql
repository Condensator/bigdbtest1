SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ReAccruals](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Alias] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[PostDate] [date] NOT NULL,
	[Status] [nvarchar](18) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[JobStepInstanceId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[BusinessUnitId] [bigint] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ReAccruals]  WITH CHECK ADD  CONSTRAINT [EReAccrual_BusinessUnit] FOREIGN KEY([BusinessUnitId])
REFERENCES [dbo].[BusinessUnits] ([Id])
GO
ALTER TABLE [dbo].[ReAccruals] CHECK CONSTRAINT [EReAccrual_BusinessUnit]
GO
ALTER TABLE [dbo].[ReAccruals]  WITH CHECK ADD  CONSTRAINT [EReAccrual_JobStepInstance] FOREIGN KEY([JobStepInstanceId])
REFERENCES [dbo].[JobStepInstances] ([Id])
GO
ALTER TABLE [dbo].[ReAccruals] CHECK CONSTRAINT [EReAccrual_JobStepInstance]
GO
