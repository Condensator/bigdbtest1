SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[MVRHistories](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[MVRStatus] [nvarchar](20) COLLATE Latin1_General_CI_AS NULL,
	[MVRReviewedBy] [nvarchar](13) COLLATE Latin1_General_CI_AS NULL,
	[MVRLastRunDate] [date] NULL,
	[MVRLastReviewedDate] [date] NULL,
	[Reason] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[DriverId] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[MVRHistories]  WITH CHECK ADD  CONSTRAINT [EDriver_MVRHistories] FOREIGN KEY([DriverId])
REFERENCES [dbo].[Drivers] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[MVRHistories] CHECK CONSTRAINT [EDriver_MVRHistories]
GO
