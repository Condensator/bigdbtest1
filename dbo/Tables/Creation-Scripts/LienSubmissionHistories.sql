SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LienSubmissionHistories](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[HistoryDate] [date] NULL,
	[SubmissionStatus] [nvarchar](11) COLLATE Latin1_General_CI_AS NULL,
	[SubmissionError] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[LienFilingId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[LienSubmissionHistories]  WITH CHECK ADD  CONSTRAINT [ELienSubmissionHistory_LienFiling] FOREIGN KEY([LienFilingId])
REFERENCES [dbo].[LienFilings] ([Id])
GO
ALTER TABLE [dbo].[LienSubmissionHistories] CHECK CONSTRAINT [ELienSubmissionHistory_LienFiling]
GO
