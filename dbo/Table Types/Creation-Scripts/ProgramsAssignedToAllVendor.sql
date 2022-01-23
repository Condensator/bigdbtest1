CREATE TYPE [dbo].[ProgramsAssignedToAllVendor] AS TABLE(
	[IsAssigned] [bit] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[AssignmentDate] [date] NOT NULL,
	[UnassignmentDate] [date] NULL,
	[ExternalVendorCode] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[IsDefault] [bit] NOT NULL,
	[LineofBusinessId] [bigint] NULL,
	[ProgramVendorId] [bigint] NULL,
	[ProgramId] [bigint] NOT NULL,
	[VendorId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
