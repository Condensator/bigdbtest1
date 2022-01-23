CREATE TYPE [dbo].[QueryProfileComponent] AS TABLE(
	[QueryComponent] [nvarchar](250) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[AssignedDate] [date] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[UnassignedDate] [date] NULL,
	[QueryProfileId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
