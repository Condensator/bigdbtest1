SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[EmployeesAssignedToBranches](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[ActivationDate] [date] NOT NULL,
	[DeactivationDate] [date] NULL,
	[IsPrimary] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RoleFunctionId] [bigint] NOT NULL,
	[EmployeeId] [bigint] NOT NULL,
	[BranchId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[EmployeesAssignedToBranches]  WITH CHECK ADD  CONSTRAINT [EBranch_EmployeesAssignedToBranches] FOREIGN KEY([BranchId])
REFERENCES [dbo].[Branches] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[EmployeesAssignedToBranches] CHECK CONSTRAINT [EBranch_EmployeesAssignedToBranches]
GO
ALTER TABLE [dbo].[EmployeesAssignedToBranches]  WITH CHECK ADD  CONSTRAINT [EEmployeesAssignedToBranch_Employee] FOREIGN KEY([EmployeeId])
REFERENCES [dbo].[Users] ([Id])
GO
ALTER TABLE [dbo].[EmployeesAssignedToBranches] CHECK CONSTRAINT [EEmployeesAssignedToBranch_Employee]
GO
ALTER TABLE [dbo].[EmployeesAssignedToBranches]  WITH CHECK ADD  CONSTRAINT [EEmployeesAssignedToBranch_RoleFunction] FOREIGN KEY([RoleFunctionId])
REFERENCES [dbo].[RoleFunctions] ([Id])
GO
ALTER TABLE [dbo].[EmployeesAssignedToBranches] CHECK CONSTRAINT [EEmployeesAssignedToBranch_RoleFunction]
GO
