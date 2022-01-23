SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LienRecordStatusHistories](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[HistoryDate] [date] NULL,
	[RecordStatus] [nvarchar](10) COLLATE Latin1_General_CI_AS NULL,
	[FilingType] [nvarchar](21) COLLATE Latin1_General_CI_AS NULL,
	[FilingStatus] [nvarchar](23) COLLATE Latin1_General_CI_AS NULL,
	[FileNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[FileDate] [date] NULL,
	[OriginalFileDate] [date] NULL,
	[ExpiryDate] [date] NULL,
	[FilingOffice] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[RejectedReason] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[ResponseError] [nvarchar](max) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[FilingStateId] [bigint] NOT NULL,
	[LienFilingId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[LienRecordStatusHistories]  WITH CHECK ADD  CONSTRAINT [ELienRecordStatusHistory_FilingState] FOREIGN KEY([FilingStateId])
REFERENCES [dbo].[States] ([Id])
GO
ALTER TABLE [dbo].[LienRecordStatusHistories] CHECK CONSTRAINT [ELienRecordStatusHistory_FilingState]
GO
ALTER TABLE [dbo].[LienRecordStatusHistories]  WITH CHECK ADD  CONSTRAINT [ELienRecordStatusHistory_LienFiling] FOREIGN KEY([LienFilingId])
REFERENCES [dbo].[LienFilings] ([Id])
GO
ALTER TABLE [dbo].[LienRecordStatusHistories] CHECK CONSTRAINT [ELienRecordStatusHistory_LienFiling]
GO
