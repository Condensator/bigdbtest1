SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ProgramDefaultSalesRepAssignmentDetails](
	[Type] [nvarchar](11) COLLATE Latin1_General_CI_AS NULL,
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[UploadFile_Source] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[UploadFile_Type] [nvarchar](5) COLLATE Latin1_General_CI_AS NULL,
	[UploadFile_Content] [varbinary](82) NULL,
	[UploadDate] [date] NULL,
	[IsActive] [bit] NOT NULL,
	[UploadById] [bigint] NULL,
	[ProgramDefaultSalesRepAssignmentId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ProgramDefaultSalesRepAssignmentDetails]  WITH CHECK ADD  CONSTRAINT [EProgramDefaultSalesRepAssignment_ProgramDefaultSalesRepAssignmentDetails] FOREIGN KEY([ProgramDefaultSalesRepAssignmentId])
REFERENCES [dbo].[ProgramDefaultSalesRepAssignments] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[ProgramDefaultSalesRepAssignmentDetails] CHECK CONSTRAINT [EProgramDefaultSalesRepAssignment_ProgramDefaultSalesRepAssignmentDetails]
GO
ALTER TABLE [dbo].[ProgramDefaultSalesRepAssignmentDetails]  WITH CHECK ADD  CONSTRAINT [EProgramDefaultSalesRepAssignmentDetail_UploadBy] FOREIGN KEY([UploadById])
REFERENCES [dbo].[Users] ([Id])
GO
ALTER TABLE [dbo].[ProgramDefaultSalesRepAssignmentDetails] CHECK CONSTRAINT [EProgramDefaultSalesRepAssignmentDetail_UploadBy]
GO
