SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[EmployeesAssignedToAssumptions](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[ActivationDate] [date] NOT NULL,
	[DeactivationDate] [date] NULL,
	[IsActive] [bit] NOT NULL,
	[IsPrimary] [bit] NOT NULL,
	[IsDisplayDashboard] [bit] NOT NULL,
	[IsNewlyAdded] [bit] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[EmployeeAssignedToPartyId] [bigint] NOT NULL,
	[AssumptionId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[CustomerId] [bigint] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[EmployeesAssignedToAssumptions]  WITH CHECK ADD  CONSTRAINT [EAssumption_EmployeesAssignedToAssumptions] FOREIGN KEY([AssumptionId])
REFERENCES [dbo].[Assumptions] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[EmployeesAssignedToAssumptions] CHECK CONSTRAINT [EAssumption_EmployeesAssignedToAssumptions]
GO
ALTER TABLE [dbo].[EmployeesAssignedToAssumptions]  WITH CHECK ADD  CONSTRAINT [EEmployeesAssignedToAssumption_Customer] FOREIGN KEY([CustomerId])
REFERENCES [dbo].[Customers] ([Id])
GO
ALTER TABLE [dbo].[EmployeesAssignedToAssumptions] CHECK CONSTRAINT [EEmployeesAssignedToAssumption_Customer]
GO
ALTER TABLE [dbo].[EmployeesAssignedToAssumptions]  WITH CHECK ADD  CONSTRAINT [EEmployeesAssignedToAssumption_EmployeeAssignedToParty] FOREIGN KEY([EmployeeAssignedToPartyId])
REFERENCES [dbo].[EmployeesAssignedToParties] ([Id])
GO
ALTER TABLE [dbo].[EmployeesAssignedToAssumptions] CHECK CONSTRAINT [EEmployeesAssignedToAssumption_EmployeeAssignedToParty]
GO
