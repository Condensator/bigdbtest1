CREATE TYPE [dbo].[EmployeesAssignedToParty] AS TABLE(
	[IsActive] [bit] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ActivationDate] [date] NOT NULL,
	[DeactivationDate] [date] NULL,
	[IsPrimary] [bit] NOT NULL,
	[IsFromAssumption] [bit] NOT NULL,
	[IsAssumptionApproved] [bit] NOT NULL,
	[PartyRole] [nvarchar](16) COLLATE Latin1_General_CI_AS NOT NULL,
	[RoleFunctionId] [bigint] NOT NULL,
	[EmployeeId] [bigint] NOT NULL,
	[PartyId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
