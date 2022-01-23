SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ProgramDefaultSalesRepAssignments](
	[TerritoryType] [nvarchar](11) COLLATE Latin1_General_CI_AS NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[CriteriaType] [nvarchar](13) COLLATE Latin1_General_CI_AS NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ProgramDefaultSalesRepAssignments]  WITH CHECK ADD  CONSTRAINT [EProgramDetail_ProgramDefaultSalesRepAssignment] FOREIGN KEY([Id])
REFERENCES [dbo].[ProgramDetails] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[ProgramDefaultSalesRepAssignments] CHECK CONSTRAINT [EProgramDetail_ProgramDefaultSalesRepAssignment]
GO
