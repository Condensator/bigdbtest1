CREATE TYPE [dbo].[EmployeesAssignedToProposal] AS TABLE(
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
	[ProposalId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
