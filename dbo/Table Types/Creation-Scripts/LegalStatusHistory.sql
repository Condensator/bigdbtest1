CREATE TYPE [dbo].[LegalStatusHistory] AS TABLE(
	[AssignmentDate] [date] NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[IsActive] [bit] NOT NULL,
	[SourceModule] [nvarchar](14) COLLATE Latin1_General_CI_AS NOT NULL,
	[LegalStatusId] [bigint] NULL,
	[CustomerId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
