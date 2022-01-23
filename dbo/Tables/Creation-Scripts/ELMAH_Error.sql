SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ELMAH_Error](
	[ErrorId] [uniqueidentifier] NOT NULL,
	[Application] [nvarchar](60) COLLATE Latin1_General_CI_AS NOT NULL,
	[Host] [nvarchar](50) COLLATE Latin1_General_CI_AS NOT NULL,
	[Type] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[Source] [nvarchar](60) COLLATE Latin1_General_CI_AS NOT NULL,
	[Message] [nvarchar](500) COLLATE Latin1_General_CI_AS NOT NULL,
	[User] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[StatusCode] [int] NOT NULL,
	[TimeUtc] [datetime] NOT NULL,
	[Sequence] [int] IDENTITY(1,1) NOT NULL,
	[AllXml] [nvarchar](max) COLLATE Latin1_General_CI_AS NOT NULL,
 CONSTRAINT [PK_ELMAH_Error] PRIMARY KEY NONCLUSTERED 
(
	[ErrorId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ELMAH_Error] ADD  CONSTRAINT [DF_ELMAH_Error_ErrorId]  DEFAULT (newid()) FOR [ErrorId]
GO
