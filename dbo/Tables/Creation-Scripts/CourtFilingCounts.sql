SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CourtFilingCounts](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Count] [nvarchar](10) COLLATE Latin1_General_CI_AS NOT NULL,
	[Description] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[CourtFilingId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CourtFilingCounts]  WITH CHECK ADD  CONSTRAINT [ECourtFiling_CourtFilingCounts] FOREIGN KEY([CourtFilingId])
REFERENCES [dbo].[CourtFilings] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[CourtFilingCounts] CHECK CONSTRAINT [ECourtFiling_CourtFilingCounts]
GO
