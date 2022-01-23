SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ApproveOnBehalfOfs](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[RowNumber] [int] NOT NULL,
	[Limit_Amount] [decimal](24, 2) NOT NULL,
	[Limit_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[UserId] [bigint] NOT NULL,
	[AuthorityId] [bigint] NOT NULL,
	[ApproveOnBehalfOfUserId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ApproveOnBehalfOfs]  WITH CHECK ADD  CONSTRAINT [EApproveOnBehalfOf_ApproveOnBehalfOfUser] FOREIGN KEY([ApproveOnBehalfOfUserId])
REFERENCES [dbo].[Users] ([Id])
GO
ALTER TABLE [dbo].[ApproveOnBehalfOfs] CHECK CONSTRAINT [EApproveOnBehalfOf_ApproveOnBehalfOfUser]
GO
ALTER TABLE [dbo].[ApproveOnBehalfOfs]  WITH CHECK ADD  CONSTRAINT [EApproveOnBehalfOf_Authority] FOREIGN KEY([AuthorityId])
REFERENCES [dbo].[Authorities] ([Id])
GO
ALTER TABLE [dbo].[ApproveOnBehalfOfs] CHECK CONSTRAINT [EApproveOnBehalfOf_Authority]
GO
ALTER TABLE [dbo].[ApproveOnBehalfOfs]  WITH CHECK ADD  CONSTRAINT [EUser_ApproveOnBehalfOfs] FOREIGN KEY([UserId])
REFERENCES [dbo].[Users] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[ApproveOnBehalfOfs] CHECK CONSTRAINT [EUser_ApproveOnBehalfOfs]
GO
