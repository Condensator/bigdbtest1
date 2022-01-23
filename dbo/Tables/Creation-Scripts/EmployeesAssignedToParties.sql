SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[EmployeesAssignedToParties](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[ActivationDate] [date] NOT NULL,
	[DeactivationDate] [date] NULL,
	[IsPrimary] [bit] NOT NULL,
	[IsFromAssumption] [bit] NOT NULL,
	[IsAssumptionApproved] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RoleFunctionId] [bigint] NOT NULL,
	[EmployeeId] [bigint] NOT NULL,
	[PartyId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[PartyRole] [nvarchar](16) COLLATE Latin1_General_CI_AS NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[EmployeesAssignedToParties]  WITH CHECK ADD  CONSTRAINT [EEmployeesAssignedToParty_Employee] FOREIGN KEY([EmployeeId])
REFERENCES [dbo].[Users] ([Id])
GO
ALTER TABLE [dbo].[EmployeesAssignedToParties] CHECK CONSTRAINT [EEmployeesAssignedToParty_Employee]
GO
ALTER TABLE [dbo].[EmployeesAssignedToParties]  WITH CHECK ADD  CONSTRAINT [EEmployeesAssignedToParty_RoleFunction] FOREIGN KEY([RoleFunctionId])
REFERENCES [dbo].[RoleFunctions] ([Id])
GO
ALTER TABLE [dbo].[EmployeesAssignedToParties] CHECK CONSTRAINT [EEmployeesAssignedToParty_RoleFunction]
GO
ALTER TABLE [dbo].[EmployeesAssignedToParties]  WITH CHECK ADD  CONSTRAINT [EParty_EmployeesAssignedToParties] FOREIGN KEY([PartyId])
REFERENCES [dbo].[Parties] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[EmployeesAssignedToParties] CHECK CONSTRAINT [EParty_EmployeesAssignedToParties]
GO
