SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[EmployeesAssignedToContracts](
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
	[ContractId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[IsSignatory] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[EmployeesAssignedToContracts]  WITH CHECK ADD  CONSTRAINT [EContract_EmployeesAssignedToContracts] FOREIGN KEY([ContractId])
REFERENCES [dbo].[Contracts] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[EmployeesAssignedToContracts] CHECK CONSTRAINT [EContract_EmployeesAssignedToContracts]
GO
ALTER TABLE [dbo].[EmployeesAssignedToContracts]  WITH CHECK ADD  CONSTRAINT [EEmployeesAssignedToContract_EmployeeAssignedToParty] FOREIGN KEY([EmployeeAssignedToPartyId])
REFERENCES [dbo].[EmployeesAssignedToParties] ([Id])
GO
ALTER TABLE [dbo].[EmployeesAssignedToContracts] CHECK CONSTRAINT [EEmployeesAssignedToContract_EmployeeAssignedToParty]
GO
