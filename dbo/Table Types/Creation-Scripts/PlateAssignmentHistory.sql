CREATE TYPE [dbo].[PlateAssignmentHistory] AS TABLE(
	[IssuedDate] [date] NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[AssignedDate] [date] NOT NULL,
	[UnassignedDate] [date] NULL,
	[LastModifiedDate] [datetimeoffset](7) NOT NULL,
	[PlateHistoryReason] [nvarchar](15) COLLATE Latin1_General_CI_AS NOT NULL,
	[AssetId] [bigint] NULL,
	[CustomerId] [bigint] NULL,
	[ContractId] [bigint] NULL,
	[UserId] [bigint] NULL,
	[PlateTypeId] [bigint] NOT NULL,
	[PlateId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
