SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[MaturityMonitorLesseeNotifications](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[NotificationNumber] [int] NOT NULL,
	[NoticeReceivedDate] [date] NOT NULL,
	[ContractOptionSelected] [nvarchar](20) COLLATE Latin1_General_CI_AS NOT NULL,
	[Response] [nvarchar](7) COLLATE Latin1_General_CI_AS NOT NULL,
	[Status] [nvarchar](8) COLLATE Latin1_General_CI_AS NOT NULL,
	[EffectiveMaturityDate] [date] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RenewalDetailId] [bigint] NULL,
	[ContractOptionId] [bigint] NULL,
	[MaturityMonitorId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[MaturityMonitorLesseeNotifications]  WITH CHECK ADD  CONSTRAINT [EMaturityMonitor_MaturityMonitorLesseeNotifications] FOREIGN KEY([MaturityMonitorId])
REFERENCES [dbo].[MaturityMonitors] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[MaturityMonitorLesseeNotifications] CHECK CONSTRAINT [EMaturityMonitor_MaturityMonitorLesseeNotifications]
GO
ALTER TABLE [dbo].[MaturityMonitorLesseeNotifications]  WITH CHECK ADD  CONSTRAINT [EMaturityMonitorLesseeNotification_ContractOption] FOREIGN KEY([ContractOptionId])
REFERENCES [dbo].[LeaseContractOptions] ([Id])
GO
ALTER TABLE [dbo].[MaturityMonitorLesseeNotifications] CHECK CONSTRAINT [EMaturityMonitorLesseeNotification_ContractOption]
GO
ALTER TABLE [dbo].[MaturityMonitorLesseeNotifications]  WITH CHECK ADD  CONSTRAINT [EMaturityMonitorLesseeNotification_RenewalDetail] FOREIGN KEY([RenewalDetailId])
REFERENCES [dbo].[MaturityMonitorRenewalDetails] ([Id])
GO
ALTER TABLE [dbo].[MaturityMonitorLesseeNotifications] CHECK CONSTRAINT [EMaturityMonitorLesseeNotification_RenewalDetail]
GO
