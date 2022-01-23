SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[GLSegmentTypeDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[GLEntityType] [nvarchar](23) COLLATE Latin1_General_CI_AS NOT NULL,
	[Expression] [nvarchar](250) COLLATE Latin1_General_CI_AS NULL,
	[StaticSegmentValue] [nvarchar](5) COLLATE Latin1_General_CI_AS NULL,
	[Description] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[GLSegmentTypeId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[GLSegmentTypeDetails]  WITH CHECK ADD  CONSTRAINT [EGLSegmentType_GLSegmentTypeDetails] FOREIGN KEY([GLSegmentTypeId])
REFERENCES [dbo].[GLSegmentTypes] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[GLSegmentTypeDetails] CHECK CONSTRAINT [EGLSegmentType_GLSegmentTypeDetails]
GO
