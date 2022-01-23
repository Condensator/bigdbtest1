CREATE TYPE [dbo].[EmployeesAssignedToAssumption] AS TABLE(
	[ActivationDate] [date] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[DeactivationDate] [date] NULL,
	[IsActive] [bit] NOT NULL,
	[IsPrimary] [bit] NOT NULL,
	[IsDisplayDashboard] [bit] NOT NULL,
	[IsNewlyAdded] [bit] NOT NULL,
	[EmployeeAssignedToPartyId] [bigint] NOT NULL,
	[CustomerId] [bigint] NOT NULL,
	[AssumptionId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
