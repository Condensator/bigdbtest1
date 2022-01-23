CREATE TYPE [dbo].[EmployeesAssignedToCreditApplication] AS TABLE(
	[IsActive] [bit] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ActivationDate] [date] NOT NULL,
	[DeactivationDate] [date] NULL,
	[IsPrimary] [bit] NOT NULL,
	[IsDisplayDashboard] [bit] NOT NULL,
	[EmployeeAssignedToPartyId] [bigint] NOT NULL,
	[CreditApplicationId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
