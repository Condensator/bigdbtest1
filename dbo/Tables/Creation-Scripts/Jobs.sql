SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Jobs](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[EffectiveDate] [datetimeoffset](7) NOT NULL,
	[ExpiryDate] [datetimeoffset](7) NULL,
	[ScheduleType] [nvarchar](9) COLLATE Latin1_General_CI_AS NOT NULL,
	[ScheduleDate] [datetimeoffset](7) NULL,
	[CronExpression] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[Description] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[ScheduledStatus] [nvarchar](12) COLLATE Latin1_General_CI_AS NOT NULL,
	[ApprovalStatus] [nvarchar](9) COLLATE Latin1_General_CI_AS NOT NULL,
	[SubmittedCulture] [nvarchar](10) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsNotify] [bit] NOT NULL,
	[RunOnHolidayOption] [nvarchar](9) COLLATE Latin1_General_CI_AS NOT NULL,
	[RunDateOptions] [nvarchar](14) COLLATE Latin1_General_CI_AS NULL,
	[IsCritical] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[SubmittedUserId] [bigint] NOT NULL,
	[BusinessUnitId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[SourceSiteId] [bigint] NOT NULL,
	[JobServiceId] [bigint] NULL,
	[IsSystemJob] [bit] NOT NULL,
	[Privacy] [nvarchar](7) COLLATE Latin1_General_CI_AS NOT NULL,
	[CustomerId] [bigint] NULL,
	[OccurenceType] [nvarchar](12) COLLATE Latin1_General_CI_AS NULL,
	[CutoffTime] [datetimeoffset](7) NULL,
	[IsServiceCall] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[Jobs]  WITH CHECK ADD  CONSTRAINT [EJob_BusinessUnit] FOREIGN KEY([BusinessUnitId])
REFERENCES [dbo].[BusinessUnits] ([Id])
GO
ALTER TABLE [dbo].[Jobs] CHECK CONSTRAINT [EJob_BusinessUnit]
GO
ALTER TABLE [dbo].[Jobs]  WITH CHECK ADD  CONSTRAINT [EJob_JobService] FOREIGN KEY([JobServiceId])
REFERENCES [dbo].[JobServices] ([Id])
GO
ALTER TABLE [dbo].[Jobs] CHECK CONSTRAINT [EJob_JobService]
GO
ALTER TABLE [dbo].[Jobs]  WITH CHECK ADD  CONSTRAINT [EJob_SourceSite] FOREIGN KEY([SourceSiteId])
REFERENCES [dbo].[SubSystemConfigs] ([Id])
GO
ALTER TABLE [dbo].[Jobs] CHECK CONSTRAINT [EJob_SourceSite]
GO
ALTER TABLE [dbo].[Jobs]  WITH CHECK ADD  CONSTRAINT [EJob_SubmittedUser] FOREIGN KEY([SubmittedUserId])
REFERENCES [dbo].[Users] ([Id])
GO
ALTER TABLE [dbo].[Jobs] CHECK CONSTRAINT [EJob_SubmittedUser]
GO
