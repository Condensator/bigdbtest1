CREATE TYPE [dbo].[DealTeamDetails] AS TABLE(
	[DisplayInDashboard] [bit] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[AssignedDate] [date] NULL,
	[UnassignedDate] [date] NULL,
	[Primary] [bit] NOT NULL,
	[Assign] [bit] NOT NULL,
	[UserId] [bigint] NOT NULL,
	[RoleFunctionId] [bigint] NOT NULL,
	[DealTeamId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
