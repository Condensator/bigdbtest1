SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DealTeamDetails](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[DisplayInDashboard] [bit] NOT NULL,
	[AssignedDate] [date] NULL,
	[UnassignedDate] [date] NULL,
	[Primary] [bit] NOT NULL,
	[Assign] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[UserId] [bigint] NOT NULL,
	[RoleFunctionId] [bigint] NOT NULL,
	[DealTeamId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[DealTeamDetails]  WITH CHECK ADD  CONSTRAINT [EDealTeam_DealTeamDetails] FOREIGN KEY([DealTeamId])
REFERENCES [dbo].[DealTeams] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[DealTeamDetails] CHECK CONSTRAINT [EDealTeam_DealTeamDetails]
GO
ALTER TABLE [dbo].[DealTeamDetails]  WITH CHECK ADD  CONSTRAINT [EDealTeamDetails_RoleFunction] FOREIGN KEY([RoleFunctionId])
REFERENCES [dbo].[RoleFunctions] ([Id])
GO
ALTER TABLE [dbo].[DealTeamDetails] CHECK CONSTRAINT [EDealTeamDetails_RoleFunction]
GO
ALTER TABLE [dbo].[DealTeamDetails]  WITH CHECK ADD  CONSTRAINT [EDealTeamDetails_User] FOREIGN KEY([UserId])
REFERENCES [dbo].[Users] ([Id])
GO
ALTER TABLE [dbo].[DealTeamDetails] CHECK CONSTRAINT [EDealTeamDetails_User]
GO
