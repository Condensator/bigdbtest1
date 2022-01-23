SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[GLUserBooks](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[SystemDefinedBook] [nvarchar](4) COLLATE Latin1_General_CI_AS NOT NULL,
	[NumberOfSegments] [int] NOT NULL,
	[GLSystemDatabase] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[Description] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[ActivationDate] [date] NOT NULL,
	[DeactivationDate] [date] NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[GLConfigurationId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[GLUserBooks]  WITH CHECK ADD  CONSTRAINT [EGLConfiguration_GLUserBooks] FOREIGN KEY([GLConfigurationId])
REFERENCES [dbo].[GLConfigurations] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[GLUserBooks] CHECK CONSTRAINT [EGLConfiguration_GLUserBooks]
GO
