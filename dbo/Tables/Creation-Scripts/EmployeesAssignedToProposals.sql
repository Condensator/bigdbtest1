SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[EmployeesAssignedToProposals](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[ActivationDate] [date] NOT NULL,
	[DeactivationDate] [date] NULL,
	[IsPrimary] [bit] NOT NULL,
	[IsDisplayDashboard] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[EmployeeAssignedToPartyId] [bigint] NOT NULL,
	[ProposalId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[EmployeesAssignedToProposals]  WITH CHECK ADD  CONSTRAINT [EEmployeesAssignedToProposal_EmployeeAssignedToParty] FOREIGN KEY([EmployeeAssignedToPartyId])
REFERENCES [dbo].[EmployeesAssignedToParties] ([Id])
GO
ALTER TABLE [dbo].[EmployeesAssignedToProposals] CHECK CONSTRAINT [EEmployeesAssignedToProposal_EmployeeAssignedToParty]
GO
ALTER TABLE [dbo].[EmployeesAssignedToProposals]  WITH CHECK ADD  CONSTRAINT [EProposal_EmployeesAssignedToProposals] FOREIGN KEY([ProposalId])
REFERENCES [dbo].[Proposals] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[EmployeesAssignedToProposals] CHECK CONSTRAINT [EProposal_EmployeesAssignedToProposals]
GO
