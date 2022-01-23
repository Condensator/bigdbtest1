SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ActivityTypeSubSystemDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Viewable] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[SubSystemId] [bigint] NOT NULL,
	[ActivityTypeId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ActivityTypeSubSystemDetails]  WITH CHECK ADD  CONSTRAINT [EActivityType_ActivityTypeSubSystemDetails] FOREIGN KEY([ActivityTypeId])
REFERENCES [dbo].[ActivityTypes] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[ActivityTypeSubSystemDetails] CHECK CONSTRAINT [EActivityType_ActivityTypeSubSystemDetails]
GO
ALTER TABLE [dbo].[ActivityTypeSubSystemDetails]  WITH CHECK ADD  CONSTRAINT [EActivityTypeSubSystemDetail_SubSystem] FOREIGN KEY([SubSystemId])
REFERENCES [dbo].[SubSystemConfigs] ([Id])
GO
ALTER TABLE [dbo].[ActivityTypeSubSystemDetails] CHECK CONSTRAINT [EActivityTypeSubSystemDetail_SubSystem]
GO
