SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ACHRunDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[EntityId] [bigint] NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ACHRunId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[TraceNumber] [nvarchar](20) COLLATE Latin1_General_CI_AS NULL,
	[ACHRunFileId] [bigint] NULL,
	[IsReversed] [bit] NOT NULL,
	[IsPending] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ACHRunDetails]  WITH CHECK ADD  CONSTRAINT [EACHRun_ACHRunDetails] FOREIGN KEY([ACHRunId])
REFERENCES [dbo].[ACHRuns] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[ACHRunDetails] CHECK CONSTRAINT [EACHRun_ACHRunDetails]
GO
ALTER TABLE [dbo].[ACHRunDetails]  WITH CHECK ADD  CONSTRAINT [EACHRunDetail_ACHRunFile] FOREIGN KEY([ACHRunFileId])
REFERENCES [dbo].[ACHRunFiles] ([Id])
GO
ALTER TABLE [dbo].[ACHRunDetails] CHECK CONSTRAINT [EACHRunDetail_ACHRunFile]
GO
