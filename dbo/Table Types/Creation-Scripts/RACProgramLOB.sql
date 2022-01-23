CREATE TYPE [dbo].[RACProgramLOB] AS TABLE(
	[AssignmentDate] [date] NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[UnAssignmentDate] [date] NULL,
	[IsActive] [bit] NOT NULL,
	[LineofBusinessId] [bigint] NULL,
	[RACProgramId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
