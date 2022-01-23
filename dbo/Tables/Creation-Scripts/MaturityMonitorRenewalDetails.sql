SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[MaturityMonitorRenewalDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[RenewalTerm] [int] NULL,
	[RenewalFrequency] [nvarchar](13) COLLATE Latin1_General_CI_AS NULL,
	[RenewalAmount_Amount] [decimal](16, 2) NULL,
	[RenewalAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[RenewalDate] [date] NULL,
	[RenewalComment] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RenewalApprovedById] [bigint] NULL,
	[ContractOptionId] [bigint] NULL,
	[MaturityMonitorId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[MaturityMonitorRenewalDetails]  WITH CHECK ADD  CONSTRAINT [EMaturityMonitor_MaturityMonitorRenewalDetails] FOREIGN KEY([MaturityMonitorId])
REFERENCES [dbo].[MaturityMonitors] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[MaturityMonitorRenewalDetails] CHECK CONSTRAINT [EMaturityMonitor_MaturityMonitorRenewalDetails]
GO
ALTER TABLE [dbo].[MaturityMonitorRenewalDetails]  WITH CHECK ADD  CONSTRAINT [EMaturityMonitorRenewalDetail_ContractOption] FOREIGN KEY([ContractOptionId])
REFERENCES [dbo].[LeaseContractOptions] ([Id])
GO
ALTER TABLE [dbo].[MaturityMonitorRenewalDetails] CHECK CONSTRAINT [EMaturityMonitorRenewalDetail_ContractOption]
GO
ALTER TABLE [dbo].[MaturityMonitorRenewalDetails]  WITH CHECK ADD  CONSTRAINT [EMaturityMonitorRenewalDetail_RenewalApprovedBy] FOREIGN KEY([RenewalApprovedById])
REFERENCES [dbo].[Users] ([Id])
GO
ALTER TABLE [dbo].[MaturityMonitorRenewalDetails] CHECK CONSTRAINT [EMaturityMonitorRenewalDetail_RenewalApprovedBy]
GO
