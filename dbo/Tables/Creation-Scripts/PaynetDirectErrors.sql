SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PaynetDirectErrors](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[ErrorCode] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[Description] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[LoggedDate] [date] NULL,
	[User] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[IsFromWorkFlow] [bit] NOT NULL,
	[ResponseName] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[PaynetDirectDetailId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[PaynetDirectErrors]  WITH CHECK ADD  CONSTRAINT [EPaynetDirectDetail_PaynetDirectErrors] FOREIGN KEY([PaynetDirectDetailId])
REFERENCES [dbo].[PaynetDirectDetails] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[PaynetDirectErrors] CHECK CONSTRAINT [EPaynetDirectDetail_PaynetDirectErrors]
GO
