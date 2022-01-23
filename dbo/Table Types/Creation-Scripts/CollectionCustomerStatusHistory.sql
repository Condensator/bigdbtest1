CREATE TYPE [dbo].[CollectionCustomerStatusHistory] AS TABLE(
	[AssignmentMethod] [nvarchar](9) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[AssignmentDate] [date] NOT NULL,
	[CustomerId] [bigint] NOT NULL,
	[CollectionStatusId] [bigint] NOT NULL,
	[AssignedByUserId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
