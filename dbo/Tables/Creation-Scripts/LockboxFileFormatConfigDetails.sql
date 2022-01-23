SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LockboxFileFormatConfigDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[FieldName] [nvarchar](50) COLLATE Latin1_General_CI_AS NOT NULL,
	[StartPosition] [int] NOT NULL,
	[Length] [int] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[Description] [nvarchar](250) COLLATE Latin1_General_CI_AS NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[LockboxFileFormatConfigId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[LockboxFileFormatConfigDetails]  WITH CHECK ADD  CONSTRAINT [ELockboxFileFormatConfig_LockboxFileFormatConfigDetails] FOREIGN KEY([LockboxFileFormatConfigId])
REFERENCES [dbo].[LockboxFileFormatConfigs] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[LockboxFileFormatConfigDetails] CHECK CONSTRAINT [ELockboxFileFormatConfig_LockboxFileFormatConfigDetails]
GO
