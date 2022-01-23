SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[EmployeesAssignedToCreditApplications](
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
	[CreditApplicationId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[EmployeesAssignedToCreditApplications]  WITH CHECK ADD  CONSTRAINT [ECreditApplication_EmployeesAssignedToCreditApplications] FOREIGN KEY([CreditApplicationId])
REFERENCES [dbo].[CreditApplications] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[EmployeesAssignedToCreditApplications] CHECK CONSTRAINT [ECreditApplication_EmployeesAssignedToCreditApplications]
GO
ALTER TABLE [dbo].[EmployeesAssignedToCreditApplications]  WITH CHECK ADD  CONSTRAINT [EEmployeesAssignedToCreditApplication_EmployeeAssignedToParty] FOREIGN KEY([EmployeeAssignedToPartyId])
REFERENCES [dbo].[EmployeesAssignedToParties] ([Id])
GO
ALTER TABLE [dbo].[EmployeesAssignedToCreditApplications] CHECK CONSTRAINT [EEmployeesAssignedToCreditApplication_EmployeeAssignedToParty]
GO
