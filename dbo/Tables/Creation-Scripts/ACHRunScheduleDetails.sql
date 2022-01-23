SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ACHRunScheduleDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[ACHScheduleId] [bigint] NOT NULL,
	[IsOneTime] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ACHRunDetailId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ACHRunScheduleDetails]  WITH CHECK ADD  CONSTRAINT [EACHRunDetail_ACHRunScheduleDetails] FOREIGN KEY([ACHRunDetailId])
REFERENCES [dbo].[ACHRunDetails] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[ACHRunScheduleDetails] CHECK CONSTRAINT [EACHRunDetail_ACHRunScheduleDetails]
GO
