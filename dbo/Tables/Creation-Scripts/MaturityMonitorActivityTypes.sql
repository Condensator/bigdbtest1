SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[MaturityMonitorActivityTypes](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[DocumentAssigned] [bit] NOT NULL,
	[DocumentGenerate] [bit] NOT NULL,
	[Deadline] [date] NULL,
	[DocumentSentDate] [date] NULL,
	[FollowUpDate] [date] NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[MaturityActivityTypeId] [bigint] NULL,
	[MaturityMonitorId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[MaturityMonitorActivityTypes]  WITH CHECK ADD  CONSTRAINT [EMaturityMonitor_MaturityMonitorActivityTypes] FOREIGN KEY([MaturityMonitorId])
REFERENCES [dbo].[MaturityMonitors] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[MaturityMonitorActivityTypes] CHECK CONSTRAINT [EMaturityMonitor_MaturityMonitorActivityTypes]
GO
ALTER TABLE [dbo].[MaturityMonitorActivityTypes]  WITH CHECK ADD  CONSTRAINT [EMaturityMonitorActivityType_MaturityActivityType] FOREIGN KEY([MaturityActivityTypeId])
REFERENCES [dbo].[MaturityActivityTypes] ([Id])
GO
ALTER TABLE [dbo].[MaturityMonitorActivityTypes] CHECK CONSTRAINT [EMaturityMonitorActivityType_MaturityActivityType]
GO
