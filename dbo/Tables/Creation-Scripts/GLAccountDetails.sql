SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[GLAccountDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[SegmentNumber] [int] NOT NULL,
	[IsDynamic] [bit] NOT NULL,
	[SegmentValue] [nvarchar](12) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[DynamicSegmentTypeId] [bigint] NULL,
	[GLAccountId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[GLAccountDetails]  WITH CHECK ADD  CONSTRAINT [EGLAccount_GLAccountDetails] FOREIGN KEY([GLAccountId])
REFERENCES [dbo].[GLAccounts] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[GLAccountDetails] CHECK CONSTRAINT [EGLAccount_GLAccountDetails]
GO
ALTER TABLE [dbo].[GLAccountDetails]  WITH CHECK ADD  CONSTRAINT [EGLAccountDetail_DynamicSegmentType] FOREIGN KEY([DynamicSegmentTypeId])
REFERENCES [dbo].[GLSegmentTypes] ([Id])
GO
ALTER TABLE [dbo].[GLAccountDetails] CHECK CONSTRAINT [EGLAccountDetail_DynamicSegmentType]
GO
