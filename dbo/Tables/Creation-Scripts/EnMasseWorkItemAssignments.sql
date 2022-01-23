SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[EnMasseWorkItemAssignments](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[AdminMode] [bit] NOT NULL,
	[Type] [nvarchar](20) COLLATE Latin1_General_CI_AS NULL,
	[Operation] [nvarchar](8) COLLATE Latin1_General_CI_AS NOT NULL,
	[OldUserId] [bigint] NULL,
	[NewUserId] [bigint] NULL,
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
ALTER TABLE [dbo].[EnMasseWorkItemAssignments]  WITH CHECK ADD  CONSTRAINT [EEnMasseWorkItemAssignment_NewUser] FOREIGN KEY([NewUserId])
REFERENCES [dbo].[Users] ([Id])
GO
ALTER TABLE [dbo].[EnMasseWorkItemAssignments] CHECK CONSTRAINT [EEnMasseWorkItemAssignment_NewUser]
GO
ALTER TABLE [dbo].[EnMasseWorkItemAssignments]  WITH CHECK ADD  CONSTRAINT [EEnMasseWorkItemAssignment_OldUser] FOREIGN KEY([OldUserId])
REFERENCES [dbo].[Users] ([Id])
GO
ALTER TABLE [dbo].[EnMasseWorkItemAssignments] CHECK CONSTRAINT [EEnMasseWorkItemAssignment_OldUser]
GO
