SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[QueryProfileComponents](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[QueryComponent] [nvarchar](250) COLLATE Latin1_General_CI_AS NOT NULL,
	[AssignedDate] [date] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[UnassignedDate] [date] NULL,
	[QueryProfileId] [bigint] NOT NULL,
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
ALTER TABLE [dbo].[QueryProfileComponents]  WITH CHECK ADD  CONSTRAINT [EQueryProfile_QueryProfileComponents] FOREIGN KEY([QueryProfileId])
REFERENCES [dbo].[QueryProfiles] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[QueryProfileComponents] CHECK CONSTRAINT [EQueryProfile_QueryProfileComponents]
GO
