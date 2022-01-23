SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[GLSegmentTypes](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](16) COLLATE Latin1_General_CI_AS NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RowVersion] [timestamp] NOT NULL,
	[GLSegmentTypeConfigId] [bigint] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[GLSegmentTypes]  WITH CHECK ADD  CONSTRAINT [EGLSegmentType_GLSegmentTypeConfig] FOREIGN KEY([GLSegmentTypeConfigId])
REFERENCES [dbo].[GLSegmentTypeConfigs] ([Id])
GO
ALTER TABLE [dbo].[GLSegmentTypes] CHECK CONSTRAINT [EGLSegmentType_GLSegmentTypeConfig]
GO
