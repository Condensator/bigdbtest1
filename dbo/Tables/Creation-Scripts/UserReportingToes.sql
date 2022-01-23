SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[UserReportingToes](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[BeginDate] [date] NOT NULL,
	[EndDate] [date] NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ReportingToId] [bigint] NOT NULL,
	[UserId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[UserReportingToes]  WITH CHECK ADD  CONSTRAINT [EUser_UserReportingToes] FOREIGN KEY([UserId])
REFERENCES [dbo].[Users] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[UserReportingToes] CHECK CONSTRAINT [EUser_UserReportingToes]
GO
ALTER TABLE [dbo].[UserReportingToes]  WITH CHECK ADD  CONSTRAINT [EUserReportingTo_ReportingTo] FOREIGN KEY([ReportingToId])
REFERENCES [dbo].[Users] ([Id])
GO
ALTER TABLE [dbo].[UserReportingToes] CHECK CONSTRAINT [EUserReportingTo_ReportingTo]
GO
